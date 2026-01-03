import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/credit_models.dart';

class CreditService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collections
  final String _bundles = 'creditBundles';
  final String _providerCredits = 'providerCredits';
  final String _transactions = 'creditTransactions';
  final String _holds = 'creditHolds';

  // Get all available credit bundles
  Future<List<CreditBundle>> getCreditBundles() async {
    try {
      final snapshot = await _firestore.collection(_bundles).get();
      return snapshot.docs
          .map((doc) => CreditBundle.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting credit bundles: $e');
      return [];
    }
  }

  // Get credit account for the current provider
  Future<ProviderCreditAccount?> getProviderCreditAccount() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) return null;

      final doc =
          await _firestore.collection(_providerCredits).doc(user.uid).get();
      if (!doc.exists) {
        // Create a new account if it doesn't exist
        final newAccount = ProviderCreditAccount(
          providerId: user.uid,
          currentBalance: 0,
          totalPurchased: 0,
          totalUsed: 0,
          recentTransactions: [],
        );

        await _firestore
            .collection(_providerCredits)
            .doc(user.uid)
            .set(newAccount.toMap());
        return newAccount;
      }

      // Get recent transactions
      final transactionsSnapshot =
          await _firestore
              .collection(_transactions)
              .where('providerId', isEqualTo: user.uid)
              .orderBy('timestamp', descending: true)
              .limit(10)
              .get();

      List<CreditTransaction> transactions =
          transactionsSnapshot.docs
              .map((doc) => CreditTransaction.fromFirestore(doc))
              .toList();

      return ProviderCreditAccount.fromFirestore(
        doc,
        transactions: transactions,
      );
    } catch (e) {
      print('Error getting provider credit account: $e');
      return null;
    }
  }

  // Get a provider's transaction history
  Future<List<CreditTransaction>> getCreditTransactions({
    required String providerId,
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query query = _firestore
          .collection(_transactions)
          .where('providerId', isEqualTo: providerId)
          .orderBy('timestamp', descending: true);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      query = query.limit(limit);
      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) => CreditTransaction.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting credit transactions: $e');
      return [];
    }
  }

  // Purchase credits using a credit bundle
  Future<Map<String, dynamic>> purchaseCredits({
    required String bundleId,
    required String paymentMethodId,
  }) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        return {'success': false, 'message': 'User not authenticated'};
      }

      // Get the bundle
      final bundleDoc =
          await _firestore.collection(_bundles).doc(bundleId).get();
      if (!bundleDoc.exists) {
        return {'success': false, 'message': 'Credit bundle not found'};
      }

      final bundle = CreditBundle.fromFirestore(bundleDoc);

      // Process payment (in a real app, you would integrate with a payment provider here)
      // For this implementation, we'll assume payment is successful

      // Create transaction
      final String transactionId =
          _firestore.collection(_transactions).doc().id;
      final transaction = CreditTransaction(
        id: transactionId,
        providerId: user.uid,
        amount: bundle.creditAmount,
        type: 'purchase',
        description: 'Purchase of ${bundle.name} bundle',
        timestamp: DateTime.now(),
        bundleId: bundleId,
        purchaseAmount: bundle.price,
        paymentMethodId: paymentMethodId,
      );

      // Update provider account
      await _firestore.runTransaction((txn) async {
        final accountDoc = await txn.get(
          _firestore.collection(_providerCredits).doc(user.uid),
        );

        if (!accountDoc.exists) {
          // Create new account if it doesn't exist
          final newAccount = {
            'providerId': user.uid,
            'currentBalance': bundle.creditAmount,
            'totalPurchased': bundle.creditAmount,
            'totalUsed': 0,
            'lastPurchaseDate': FieldValue.serverTimestamp(),
          };

          txn.set(
            _firestore.collection(_providerCredits).doc(user.uid),
            newAccount,
          );
        } else {
          // Update existing account
          final currentBalance = accountDoc.data()?['currentBalance'] ?? 0;
          final totalPurchased = accountDoc.data()?['totalPurchased'] ?? 0;

          txn.update(_firestore.collection(_providerCredits).doc(user.uid), {
            'currentBalance': currentBalance + bundle.creditAmount,
            'totalPurchased': totalPurchased + bundle.creditAmount,
            'lastPurchaseDate': FieldValue.serverTimestamp(),
          });
        }

        // Add transaction
        txn.set(
          _firestore.collection(_transactions).doc(transactionId),
          transaction.toMap(),
        );
      });

      return {
        'success': true,
        'message': 'Successfully purchased ${bundle.creditAmount} credits',
        'credits': bundle.creditAmount,
        'transactionId': transactionId,
      };
    } catch (e) {
      print('Error purchasing credits: $e');
      return {'success': false, 'message': 'Failed to purchase credits: $e'};
    }
  }

  // Hold credits when provider makes an offer
  Future<Map<String, dynamic>> holdCreditsForOffer({
    required int amount,
    required String requestId,
    String? seekerId,
  }) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        return {'success': false, 'message': 'User not authenticated'};
      }

      // Verify sufficient credits
      final accountDoc =
          await _firestore.collection(_providerCredits).doc(user.uid).get();
      if (!accountDoc.exists) {
        return {'success': false, 'message': 'Provider account not found'};
      }

      final currentBalance = accountDoc.data()?['currentBalance'] ?? 0;
      if (currentBalance < amount) {
        return {'success': false, 'message': 'Insufficient credits'};
      }

      // Create hold
      final holdId = _firestore.collection(_holds).doc().id;
      final hold = CreditHold(
        id: holdId,
        providerId: user.uid,
        amount: amount,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(
          const Duration(days: 7),
        ), // Hold expires in 7 days
        status: 'pending',
        requestId: requestId,
        seekerId: seekerId,
      );

      // Update balances
      await _firestore.runTransaction((txn) async {
        // Create hold
        txn.set(_firestore.collection(_holds).doc(holdId), hold.toMap());

        // Reduce available balance
        txn.update(_firestore.collection(_providerCredits).doc(user.uid), {
          'currentBalance': FieldValue.increment(-amount),
        });
      });

      return {
        'success': true,
        'message': 'Successfully placed hold on $amount credits',
        'holdId': holdId,
      };
    } catch (e) {
      print('Error holding credits: $e');
      return {'success': false, 'message': 'Failed to hold credits: $e'};
    }
  }

  // Apply credit hold when offer is accepted
  Future<Map<String, dynamic>> applyCreditHold({
    required String holdId,
    required String bookingId,
  }) async {
    try {
      final holdDoc = await _firestore.collection(_holds).doc(holdId).get();
      if (!holdDoc.exists) {
        return {'success': false, 'message': 'Credit hold not found'};
      }

      final hold = CreditHold.fromFirestore(holdDoc);
      if (hold.status != 'pending') {
        return {
          'success': false,
          'message': 'Credit hold is not in pending state',
        };
      }

      // Create transaction
      final String transactionId =
          _firestore.collection(_transactions).doc().id;
      final transaction = CreditTransaction(
        id: transactionId,
        providerId: hold.providerId,
        amount: hold.amount,
        type: 'used',
        description: 'Credits used for booking #$bookingId',
        timestamp: DateTime.now(),
        relatedBookingId: bookingId,
      );

      // Update records
      await _firestore.runTransaction((txn) async {
        // Update hold status
        txn.update(_firestore.collection(_holds).doc(holdId), {
          'status': 'applied',
        });

        // Create transaction
        txn.set(
          _firestore.collection(_transactions).doc(transactionId),
          transaction.toMap(),
        );

        // Update provider account
        txn.update(
          _firestore.collection(_providerCredits).doc(hold.providerId),
          {
            'totalUsed': FieldValue.increment(hold.amount),
            'lastUsedDate': FieldValue.serverTimestamp(),
          },
        );
      });

      return {
        'success': true,
        'message': 'Successfully applied credit hold',
        'transactionId': transactionId,
      };
    } catch (e) {
      print('Error applying credit hold: $e');
      return {'success': false, 'message': 'Failed to apply credit hold: $e'};
    }
  }

  // Release credit hold when offer is rejected or expires
  Future<Map<String, dynamic>> releaseCreditHold({
    required String holdId,
    required String reason,
  }) async {
    try {
      final holdDoc = await _firestore.collection(_holds).doc(holdId).get();
      if (!holdDoc.exists) {
        return {'success': false, 'message': 'Credit hold not found'};
      }

      final hold = CreditHold.fromFirestore(holdDoc);
      if (hold.status != 'pending') {
        return {
          'success': false,
          'message': 'Credit hold is not in pending state',
        };
      }

      // Update records
      await _firestore.runTransaction((txn) async {
        // Update hold status
        txn.update(_firestore.collection(_holds).doc(holdId), {
          'status': 'released',
        });

        // Return credits to provider balance
        txn.update(
          _firestore.collection(_providerCredits).doc(hold.providerId),
          {'currentBalance': FieldValue.increment(hold.amount)},
        );
      });

      return {
        'success': true,
        'message': 'Successfully released credit hold',
        'amount': hold.amount,
      };
    } catch (e) {
      print('Error releasing credit hold: $e');
      return {'success': false, 'message': 'Failed to release credit hold: $e'};
    }
  }

  // Automatically check and release expired holds
  // This would typically be run by a scheduled Cloud Function
  Future<void> processExpiredHolds() async {
    try {
      final now = DateTime.now();
      final snapshot =
          await _firestore
              .collection(_holds)
              .where('status', isEqualTo: 'pending')
              .where('expiresAt', isLessThan: now)
              .get();

      for (final doc in snapshot.docs) {
        final hold = CreditHold.fromFirestore(doc);
        await releaseCreditHold(holdId: hold.id, reason: 'Hold expired');
      }
    } catch (e) {
      print('Error processing expired holds: $e');
    }
  }
}

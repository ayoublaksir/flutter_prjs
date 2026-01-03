import 'package:flutter/material.dart';
import 'package:dating_app/screens/user_profile_detail_screen.dart';
import '../services/user_service.dart';
import '../models/date_offer.dart';
import '../services/date_offer_service.dart';
import 'package:provider/provider.dart';
import 'package:dating_app/services/auth_service.dart';

class DateOfferDetailsScreen extends StatefulWidget {
  final String offerId;

  const DateOfferDetailsScreen({Key? key, required this.offerId})
    : super(key: key);

  @override
  _DateOfferDetailsScreenState createState() => _DateOfferDetailsScreenState();
}

class _DateOfferDetailsScreenState extends State<DateOfferDetailsScreen> {
  final UserService _userService = UserService();
  final DateOfferService _dateOfferService = DateOfferService();
  bool _isLoading = true;
  DateOffer? _offer;

  @override
  void initState() {
    super.initState();
    _loadOffer();
  }

  Future<void> _loadOffer() async {
    setState(() => _isLoading = true);
    try {
      final offer = await _dateOfferService.getDateOfferById(widget.offerId);
      setState(() {
        _offer = offer;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      // Handle error
    }
  }

  Future<void> _viewCreatorProfile() async {
    try {
      final userProfile = await _userService.getUserProfile(_offer!.creatorId);
      if (userProfile != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => UserProfileDetailScreen(
                  userProfile: userProfile,
                  isResponder: false,
                ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading profile: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(children: [_buildCreatorInfo()]),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (!authService.isPremium)
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/premium');
                  },
                  icon: const Icon(Icons.star),
                  label: const Text('Get Premium'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreatorInfo() {
    return InkWell(
      onTap: _viewCreatorProfile,
      child: Row(
        children: [
          CircleAvatar(
            backgroundImage:
                _offer?.creatorImageUrl != null
                    ? NetworkImage(_offer!.creatorImageUrl!)
                    : null,
            child:
                _offer?.creatorImageUrl == null
                    ? Text(_offer!.creatorName[0])
                    : null,
          ),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _offer!.creatorName,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '${_offer!.creatorAge} • ${_offer!.creatorGender.toString().split('.').last}',
              ),
            ],
          ),
          Spacer(),
          Icon(Icons.arrow_forward_ios, size: 16),
        ],
      ),
    );
  }
}

/// Central vocabulary used across the Hostel feature.
///
/// Keep user-facing options here so discovery, listing and details use the
/// same values instead of maintaining separate hard-coded lists.
abstract final class HostelRegistry {
  static const genders = <String>['Male', 'Female', 'Both'];
  static const types = <String>['Private', 'University', 'College', 'Other'];
  static const roomTypes = <String>[
    'Single',
    '2-Seater',
    '3-Seater',
    '4-Seater',
    '5-Seater',
    '6-Seater',
    'Other',
  ];
  static const sortOptions = <String>[
    'Recommended',
    'Price Low',
    'Price High',
    'Nearest',
    'Top Rated',
  ];
  static const verificationStatuses = <String>[
    'pending',
    'approved',
    'rejected',
  ];

  static const commonFacilities = <String>[
    'Wi-Fi',
    'Mess',
    'Laundry',
    'CCTV',
    'Security',
    'Parking',
    'Generator',
    'Study room',
    'Study area',
    'Library access',
    'Sports',
    'Kitchen',
    'Common room',
    'Attached bath',
    'Hot water',
  ];

  static const mealOptions = <String>[
    'Mess included',
    'Breakfast',
    'Lunch',
    'Dinner',
    'Breakfast & Dinner',
    'Breakfast, Lunch & Dinner',
    'Self cooking',
    'No meals',
  ];
}

import 'package:flutter/material.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class CalendarScreen extends StatefulWidget {
  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final List<Map<String, dynamic>> schemeMonths = [
    {
      'month': 'January',
      'scheme': 'Startup India Scheme',
      'description': 'Provides tax benefits and funding support for new startups',
      'icon': Icons.business,
      'color': Colors.blue,
      'benefits': ['Tax holiday for 3 years', '80% patent fee rebate', '₹10 lakh to ₹1 crore funding'],
      'website': 'https://www.startupindia.gov.in/'
    },
    {
      'month': 'February',
      'scheme': 'PM-KISAN',
      'description': 'Financial support to small and marginal farmers',
      'icon': Icons.agriculture,
      'color': Colors.green,
      'benefits': ['₹6,000 annual income support', 'Direct bank transfer', 'All landholding farmers eligible'],
      'website': 'https://pmkisan.gov.in/'
    },
    {
      'month': 'March',
      'scheme': 'National Health Mission',
      'description': 'Improving healthcare infrastructure in rural areas',
      'icon': Icons.medical_services,
      'color': Colors.red,
      'benefits': ['Free essential medicines', 'Mobile medical units', 'Health insurance coverage'],
      'website': 'https://nhm.gov.in/'
    },
    {
      'month': 'April',
      'scheme': 'Stand-Up India',
      'description': 'Promotes entrepreneurship among SC/ST and women',
      'icon': Icons.work,
      'color': Colors.purple,
      'benefits': ['Loan from ₹10 lakh to ₹1 crore', 'Composite loan for 7 years', 'RuPay debit card'],
      'website': 'https://www.standupmitra.in/'
    },
    {
      'month': 'May',
      'scheme': 'Ujjwala Yojana',
      'description': 'Free LPG connections to women from BPL households',
      'icon': Icons.fireplace,
      'color': Colors.orange,
      'benefits': ['Free LPG connection', 'First refill and stove included', '5 crore beneficiaries'],
      'website': 'https://www.pmuy.gov.in/'
    },
    {
      'month': 'June',
      'scheme': 'Digital India',
      'description': 'Digital infrastructure and services for citizens',
      'icon': Icons.language,
      'color': Colors.indigo,
      'benefits': ['Digital literacy', 'Online government services', 'Broadband in villages'],
      'website': 'https://digitalindia.gov.in/'
    },
    {
      'month': 'July',
      'scheme': 'Skill India Mission',
      'description': 'Vocational training and skill development',
      'icon': Icons.school,
      'color': Colors.teal,
      'benefits': ['Training in various sectors', 'Certification programs', 'Job placement support'],
      'website': 'https://www.skillindia.gov.in/'
    },
    {
      'month': 'August',
      'scheme': 'Atal Pension Yojana',
      'description': 'Pension scheme for unorganized sector workers',
      'icon': Icons.account_balance_wallet,
      'color': Colors.brown,
      'benefits': ['Guaranteed pension', 'Flexible contribution', 'Government co-contribution'],
      'website': 'https://www.jansuraksha.gov.in/'
    },
    {
      'month': 'September',
      'scheme': 'Mudra Loan Scheme',
      'description': 'Financial support for small businesses',
      'icon': Icons.credit_card,
      'color': Colors.cyan,
      'benefits': ['Loans up to ₹10 lakh', 'No collateral required', 'Support for non-farm enterprises'],
      'website': 'https://www.mudra.org.in/'
    },
    {
      'month': 'October',
      'scheme': 'Swachh Bharat Abhiyan',
      'description': 'Clean India mission for sanitation and hygiene',
      'icon': Icons.cleaning_services,
      'color': Colors.deepOrange,
      'benefits': ['Toilet construction', 'Waste management', 'Clean public spaces'],
      'website': 'https://swachhbharat.mygov.in/'
    },
    {
      'month': 'November',
      'scheme': 'Ayushman Bharat',
      'description': 'Health insurance for economically vulnerable families',
      'icon': Icons.health_and_safety,
      'color': Colors.pink,
      'benefits': ['₹5 lakh coverage per family', 'Cashless hospitalization', '1500+ empaneled hospitals'],
      'website': 'https://pmjay.gov.in/'
    },
    {
      'month': 'December',
      'scheme': 'Housing for All',
      'description': 'Affordable housing in urban areas',
      'icon': Icons.home_work,
      'color': Colors.blueGrey,
      'benefits': ['Subsidy on home loans', 'Infrastructure development', 'Slum rehabilitation'],
      'website': 'https://pmay-urban.gov.in/'
    },
  ];

  int? _expandedIndex;

  @override
  Widget build(BuildContext context) {
    final currentMonth = DateFormat('MMMM').format(DateTime.now());

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Government Schemes Calendar',
            style: TextStyle(fontWeight: FontWeight.w600,color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(
          color: Colors.white, // <- This changes the back arrow to white
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.indigo.shade700, Colors.purple.shade600],
            ),
          ),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search,color: Colors.white),
            onPressed: () => _showSearchDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Current month highlight
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade50, Colors.purple.shade50],
              ),
            ),
            child: Center(
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[800],
                      fontWeight: FontWeight.w500,
                  ),
                  children: [
                    const TextSpan(text: 'Current Month: '),
                    TextSpan(
                      text: currentMonth,
                      style: TextStyle(
                          color: Colors.indigo.shade700,
                          fontWeight: FontWeight.bold
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Timeline
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: schemeMonths.length,
              itemBuilder: (context, index) {
                final isFirst = index == 0;
                final isLast = index == schemeMonths.length - 1;
                final isExpanded = _expandedIndex == index;
                final scheme = schemeMonths[index];

                return TimelineTile(
                  alignment: TimelineAlign.manual,
                  lineXY: 0.15,
                  isFirst: isFirst,
                  isLast: isLast,
                  beforeLineStyle: LineStyle(
                    color: scheme['color'],
                    thickness: 3,
                  ),
                  afterLineStyle: LineStyle(
                    color: scheme['color'],
                    thickness: 3,
                  ),
                  indicatorStyle: IndicatorStyle(
                    width: 40,
                    height: 40,
                    color: scheme['color'],
                    iconStyle: IconStyle(
                      iconData: scheme['icon'],
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                  endChild: GestureDetector(
                    onTap: () => setState(() {
                      _expandedIndex = isExpanded ? null : index;
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 2,
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                scheme['month'],
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: scheme['color'],
                                ),
                              ),
                              Icon(
                                isExpanded
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                                color: Colors.grey[600],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            scheme['scheme'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          if (isExpanded) ...[
                            const SizedBox(height: 12),
                            Text(
                              scheme['description'],
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Key Benefits:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...scheme['benefits'].map<Widget>((benefit) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    size: 16,
                                    color: scheme['color'],
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      benefit,
                                      style: TextStyle(
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )).toList(),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: () => _showSchemeDetails(context, scheme),
                                icon: Icon(
                                  Icons.info_outline,
                                  color: scheme['color'],
                                ),
                                label: Text(
                                  'More Details',
                                  style: TextStyle(
                                    color: scheme['color'],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showYearlyOverview(context),
        icon: const Icon(Icons.calendar_today,color: Colors.white,),
        label: const Text('Yearly Overview',style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.indigo.shade600,
      ),
    );
  }
  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
  Future<void> _launchWebsite(String url) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );

    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        );
      } else {
        _showErrorSnackbar('Could not launch the website');
      }
    } catch (e) {
      _showErrorSnackbar('An error occurred: ${e.toString()}');
    } finally {
      Navigator.of(context).pop(); // Dismiss loading indicator
    }
  }
  void _showSchemeDetails(BuildContext context, Map<String, dynamic> scheme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  scheme['month'],
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: scheme['color'],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              scheme['scheme'],
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              scheme['description'],
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[800],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Key Benefits:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...scheme['benefits'].map<Widget>((benefit) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: scheme['color'].withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      size: 16,
                      color: scheme['color'],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      benefit,
                      style: const TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            )).toList(),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _launchWebsite(scheme['website']),
                style: ElevatedButton.styleFrom(
                  backgroundColor: scheme['color'],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Apply for Scheme',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,color: Colors.white
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showYearlyOverview(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75, // 75% of screen height
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Yearly Schemes Overview',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                Divider(height: 1),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      shrinkWrap: true,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 0.7, // Reduced from 0.8 to fit content
                      ),
                      itemCount: schemeMonths.length,
                      itemBuilder: (context, index) {
                        final scheme = schemeMonths[index];
                        return Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              Navigator.pop(context);
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                setState(() => _expandedIndex = index);
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: scheme['color'].withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      scheme['icon'],
                                      color: scheme['color'],
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(height: 6), // Reduced from 8
                                  Text(
                                    scheme['month'].substring(0, 3),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[700],
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 2), // Reduced from 4
                                  Text(
                                    scheme['scheme'].split(' ').first,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: scheme['color'],
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Divider(height: 1),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Close',
                    style: TextStyle(color: Colors.indigo),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search schemes...',
                  prefixIcon: const Icon(Icons.search,color: Colors.white,),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {}, // Add search functionality
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Search'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
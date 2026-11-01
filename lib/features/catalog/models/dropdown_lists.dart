// File: lib/features/catalog/models/dropdown_lists.dart

class DropdownLists {
  final List<String> salesPerson;
  final List<String> paymentTerms;
  final List<String> region;
  final List<String> projectType;
  final List<String> customerType;
  final List<String> freightTerms;
  final List<String> zonalManager;
  final List<String> projectRetail;
  final List<String> orderValidity;
  final List<String> rera;

  DropdownLists({
    required this.salesPerson,
    required this.paymentTerms,
    required this.region,
    required this.projectType,
    required this.customerType,
    required this.freightTerms,
    required this.zonalManager,
    required this.projectRetail,
    required this.orderValidity,
    required this.rera,
  });

  factory DropdownLists.fromJson(Map<String, dynamic> json) {
    List<String> parseList(String key) {
      if (json[key] is List) {
        return (json[key] as List).map((e) => e.toString()).toList();
      }
      return [];
    }

    return DropdownLists(
      salesPerson: parseList('Sales Person'),
      paymentTerms: parseList('Payment Terms'),
      region: parseList('Region'),
      projectType: parseList('Project Type'),
      customerType: parseList('Customer Type'),
      freightTerms: parseList('Freight Terms'),
      zonalManager: parseList('Zonal Manager'),
      projectRetail: parseList('Project /Retail'),
      orderValidity: parseList('Order Validity'),
      rera: parseList('RERA'),
    );
  }

  static DropdownLists defaultLists() {
    return DropdownLists(
      salesPerson: [
        "International Shipments",
        "Huliot Plant 714 & 715",
        "Tushar Nag",
        "Mriganco Maiti",
        "Sumit Sharma",
        "Yuvraj Rathod",
        "Pratik Kular",
        "Himanshu Todi",
        "Mohit Gupta",
        "Yogesh Kumawat",
        "Vishal Ganwani",
        "Vikas Gupta",
        "Vivek Vandhu",
        "Devsh Arjariya",
        "Ganesh Bhosale",
        "Aditya Raj",
        "Lalit Panwar",
        "Surender Banwala",
        "Jayaraman Iyer",
        "Babu Gs",
        "Gokula Kannan",
        "Satish Kumar",
        "Santhosh Kumar N S",
        "Vasudevan S",
        "Abhishek D.H",
        "Amit Kini",
        "Karan Mule",
        "Ashish Oswal",
        "Giriraj Tupe",
        "Hetan Raval",
        "Prashant Satam",
        "Vijay More",
        "Vishal Chavan",
        "Kartik Shah",
        "Amit Chougule",
        "A Komuraiah",
        "Ajay More",
        "Sonu Kumar Pandit",
        "Laxmi Dipak",
        "Huliot South",
        "Huliot East",
        "Huliot North"
      ],
      paymentTerms: [
        "Advance ",
        "Under Udaan-Channel Finance",
        "30 Days PDC ",
        "LC at Sight",
        "LC 30 Days "
      ],
      region: [
        "International Sales ",
        "Direct Sales ",
        "North East ",
        "Central Zone ",
        "North Zone ",
        "South Zone ",
        "West Zone ",
        "Retail-Pune ",
        "Retail-South ",
        "Retail-Maharashtra "
      ],
      projectType: [
        "Individual Villa -IV",
        "Housing-Residential Project - HR",
        "Commercial Building - CB",
        "Hotel Project - HP",
        "Hospital & Healthcare - HH",
        "Industrial /Government Project - IG",
        "Marine - M",
        "Others"
      ],
      customerType: [
        "Developer ",
        "Builder ",
        "Contractor ",
        "MEP Consultant ",
        "Distributor"
      ],
      freightTerms: [
        "FOR ",
        "Ex Works ",
        "FOB (Only for Exports)",
        "CIF (Only for Exports)"
      ],
      zonalManager: ["S. Mukherjee", "Rahul Adhikari", "Amit Deshmukh "],
      projectRetail: ["Project ", "Retail "],
      orderValidity: ["7 Days ", "10 Days ", "15 Days "],
      rera: ["Bunglow", "Hospital", "Hotel ", "Government Project "],
    );
  }
}


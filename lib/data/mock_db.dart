import 'models.dart';

/// Mirrors the `const studentDB / employeeDB / ...` objects in the original
/// HTML prototype's <script> section.
class MockDb {
  MockDb._();

  static const monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  static const List<Person> studentDb = [
    Person(name: 'Ramish Ali', sub: 'DAE Bio-Medical • GR 2019-BM/M-014', code: 'S014'),
    Person(name: 'Quratul Ain Bibi', sub: 'DAE Bio-Medical • GR 2019-BM/M-001', code: 'S001'),
    Person(name: 'Ahmed Raza', sub: 'DAE Architecture • GR 2020-AR/M-022', code: 'S022'),
    Person(name: 'Fatima Noor', sub: 'DAE Electronics • GR 2021-EL/F-009', code: 'S009'),
    Person(name: 'Bilal Hussain', sub: 'DAE Architecture • GR 2019-AR/M-031', code: 'S031'),
    Person(name: 'Sana Malik', sub: 'DAE Bio-Medical • GR 2020-BM/F-017', code: 'S017'),
  ];

  static const List<Person> employeeDb = [
    Person(name: 'Shahid Jamil', sub: 'Principal • GENERAL • Code 28', code: 'E028'),
    Person(name: 'Sobia Shabir', sub: 'Lecturer • Electronics • Code 41', code: 'E041'),
    Person(name: 'Syeda Rida Fatima Rizvi', sub: 'Lecturer • Physics • Code 37', code: 'E037'),
    Person(name: 'Kamran Siddiqui', sub: 'Lab Assistant • GENERAL • Code 12', code: 'E012'),
    Person(name: 'Ayesha Tariq', sub: 'Accountant • Finance • Code 05', code: 'E005'),
  ];

  static const Map<String, List<ClassSession>> scheduleData = {
    'Monday': [
      ClassSession(
        name: 'FUNDAMENTAL OF MICRO PROCESSOR & INTERFACING TECHNIQUES',
        teacher: 'Sobia Shabir',
        time: '08:15 AM – 09:00 AM',
      ),
      ClassSession(
        name: 'OPTO ELECTRONICS, FIBER OPTICS AND LASER',
        teacher: 'Syeda Rida Fatima Rizvi',
        time: '09:45 AM – 10:30 AM',
      ),
    ],
    'Tuesday': [
      ClassSession(name: 'DIGITAL LOGIC DESIGN', teacher: 'Kamran Siddiqui', time: '08:15 AM – 09:00 AM'),
      ClassSession(name: 'ELECTRICAL MACHINES', teacher: 'Ayesha Tariq', time: '09:45 AM – 10:30 AM'),
    ],
    'Wednesday': [
      ClassSession(name: 'COMMUNICATION SKILLS', teacher: 'Sobia Shabir', time: '08:15 AM – 09:00 AM'),
    ],
    'Thursday': [
      ClassSession(name: 'PROJECT LAB', teacher: 'Syeda Rida Fatima Rizvi', time: '10:30 AM – 12:00 PM'),
    ],
    'Friday': [
      ClassSession(name: 'ISLAMIC STUDIES', teacher: 'Kamran Siddiqui', time: '08:15 AM – 09:00 AM'),
    ],
  };

  static const List<LeaveRecord> leaveDb = [
    LeaveRecord(name: 'Sobia Shabir', code: 'E041', type: 'CL', status: 'Approved', days: 2),
    LeaveRecord(name: 'Kamran Siddiqui', code: 'E012', type: 'EL', status: 'Pending', days: 5),
    LeaveRecord(name: 'Ayesha Tariq', code: 'E005', type: 'Medical', status: 'Approved', days: 1),
    LeaveRecord(
      name: 'Syeda Rida Fatima Rizvi',
      code: 'E037',
      type: 'CL',
      status: 'Rejected',
      days: 1,
    ),
  ];

  static const List<CourseProgress> courseList = [
    CourseProgress(
      name: 'Fundamental of Micro Processor & Interfacing',
      teacher: 'Sobia Shabir',
      progress: 72,
    ),
    CourseProgress(
      name: 'Opto Electronics, Fiber Optics and Laser',
      teacher: 'Syeda Rida Fatima Rizvi',
      progress: 58,
    ),
    CourseProgress(name: 'Digital Logic Design', teacher: 'Kamran Siddiqui', progress: 85),
    CourseProgress(name: 'Communication Skills', teacher: 'Sobia Shabir', progress: 40),
  ];

  static const Map<String, List<ExamEntry>> examData = {
    'mid': [
      ExamEntry(course: 'Micro Processor & Interfacing', date: '12 Aug 2026', time: '09:00 AM'),
      ExamEntry(course: 'Opto Electronics & Laser', date: '14 Aug 2026', time: '11:00 AM'),
    ],
    'final': [
      ExamEntry(course: 'Micro Processor & Interfacing', date: '20 Dec 2026', time: '09:00 AM'),
      ExamEntry(course: 'Opto Electronics & Laser', date: '22 Dec 2026', time: '09:00 AM'),
      ExamEntry(course: 'Digital Logic Design', date: '24 Dec 2026', time: '11:00 AM'),
    ],
  };

  static const Map<String, List<CalendarEntry>> academicCalData = {
    'fall': [
      CalendarEntry(date: '01 Sep 2026', event: 'Fall Term Begins'),
      CalendarEntry(date: '15 Oct 2026', event: 'Mid Term Exams'),
      CalendarEntry(date: '25 Dec 2026', event: 'Winter Break Starts'),
    ],
    'spring': [
      CalendarEntry(date: '05 Jan 2027', event: 'Spring Term Begins'),
      CalendarEntry(date: '20 Feb 2027', event: 'Mid Term Exams'),
      CalendarEntry(date: '30 Apr 2027', event: 'Final Term Exams'),
    ],
  };

  static const List<CalendarEntry> holidays = [
    CalendarEntry(date: '24 Jul 2026', event: 'PROJECT EXHIBITION'),
    CalendarEntry(date: '25 Jun 2026', event: 'MUHARRAM UL HARAM'),
    CalendarEntry(date: '25 May 2026', event: 'Eid ul Adha 2026'),
    CalendarEntry(date: '01 May 2026', event: 'Labour Day'),
    CalendarEntry(date: '03 Apr 2026', event: 'Weather – Heavy Rain'),
    CalendarEntry(date: '16 Mar 2026', event: 'Eid ul Fitr 2026'),
  ];

  static const List<CalendarEntry> studentEvents = [
    CalendarEntry(date: '13-12-2025', event: 'Graduation Ceremony'),
    CalendarEntry(date: '23-02-2025', event: 'PTM'),
    CalendarEntry(date: '21-02-2025', event: 'Badminton Girls'),
    CalendarEntry(date: '20-02-2025', event: 'Badminton Boys'),
    CalendarEntry(date: '05-02-2025', event: 'Kashmir Holiday'),
  ];

  static const Map<String, PortalMeta> portalMeta = {
    'admin': PortalMeta(name: 'Admin Portal', icon: '🖥️', demoUser: 'admin', demoPass: 'admin123'),
    'student': PortalMeta(
      name: 'Student Portal',
      icon: '🎓',
      demoUser: 'quratul.ain',
      demoPass: 'stud@2026',
    ),
    'employee': PortalMeta(
      name: 'Employee Portal',
      icon: '🧑‍💼',
      demoUser: 'shahid_jamil',
      demoPass: 'emp@2026',
    ),
  };

  static const Map<String, Map<String, int>> regStatsByYear = {
    '2024-2025': {'s': 1531, 'i': 1, 'u': 437, 'int': 1036, 't': 57},
    '2023-2024': {'s': 1420, 'i': 6, 'u': 298, 'int': 980, 't': 63},
    '2022-2023': {'s': 1305, 'i': 3, 'u': 180, 'int': 870, 't': 49},
  };

  static const List<Map<String, String>> salarySlips = [
    {'date': '22-07-26', 'amount': '284,083', 'status': 'Audited'},
    {'date': '22-06-26', 'amount': '163,902', 'status': 'Transferred'},
    {'date': '14-05-26', 'amount': '163,902', 'status': 'Transferred'},
    {'date': '28-01-26', 'amount': '314,906', 'status': 'Transferred'},
    {'date': '25-12-25', 'amount': '330,631', 'status': 'Transferred'},
  ];

  static const List<Map<String, String>> leaveBalanceRows = [
    {'name': 'CL', 'total': '15', 'avail': '0', 'remaining': '15'},
    {'name': 'EL', 'total': '30', 'avail': '13', 'remaining': '17'},
    {'name': 'EOL', 'total': '0', 'avail': '0', 'remaining': '0'},
    {'name': 'CPL', 'total': '0', 'avail': '0', 'remaining': '0'},
    {'name': 'Hajj Leave', 'total': '40', 'avail': '40', 'remaining': '0'},
    {'name': 'Umrah Leave', 'total': '15', 'avail': '15', 'remaining': '0'},
    {'name': 'Medical Leave', 'total': '30', 'avail': '30', 'remaining': '0'},
    {'name': 'Maternity Leave', 'total': '60', 'avail': '60', 'remaining': '0'},
    {'name': 'Eidat Leave', 'total': '128', 'avail': '128', 'remaining': '0'},
  ];
}

class StudentRecord {
  final String name, grNo, email, program, batch, cnic, admission, phone;
  const StudentRecord({
    required this.name,
    required this.grNo,
    required this.email,
    required this.program,
    required this.batch,
    required this.cnic,
    required this.admission,
    required this.phone,
  });
}

class EmployeeRecord {
  final String name, empId, programType, scaleType, department, staffType, email, phone;
  const EmployeeRecord({
    required this.name,
    required this.empId,
    required this.programType,
    required this.scaleType,
    required this.department,
    required this.staffType,
    required this.email,
    required this.phone,
  });
}

class NoticeItem {
  final String date, title, body;
  const NoticeItem(this.date, this.title, this.body);
}

class HolidayItem {
  final String date, name;
  const HolidayItem(this.date, this.name);
}

/// Portal login metadata: display name, icon, and the route to land on.
class PortalMeta {
  final String name;
  final String iconEmoji;
  final String dashboardRoute;
  const PortalMeta(this.name, this.iconEmoji, this.dashboardRoute);
}

const portalMeta = {
  'admin': PortalMeta('Admin Portal', '🖥️', '/admin'),
  'student': PortalMeta('Student Portal', '🎓', '/student'),
  'employee': PortalMeta('Employee Portal', '🧑‍💼', '/employee'),
  'faculty': PortalMeta('Faculty Portal', '👨‍🏫', '/faculty'),
};

const List<StudentRecord> studentDB = [
  StudentRecord(
      name: 'Ramish Ali',
      grNo: '2019-BM/M-014',
      email: '-',
      program: 'DAE Bio-Medical Technology (M)',
      batch: 'BM-2019-MOR',
      cnic: '-',
      admission: '-',
      phone: '923333 214 522'),
  StudentRecord(
      name: 'Quratul Ain Bibi',
      grNo: '2019-BM/M-001',
      email: '-',
      program: 'DAE Bio-Medical Technology (M)',
      batch: 'BM-2019-MOR',
      cnic: '-',
      admission: '-',
      phone: '922282 152 47'),
  StudentRecord(
      name: 'Amir Alam Alam',
      grNo: '2019-BM/M-005',
      email: '-',
      program: 'DAE Bio-Medical Technology (M)',
      batch: 'BM-2019-MOR',
      cnic: '-',
      admission: '-',
      phone: '923333 237 907'),
  StudentRecord(
      name: 'Fatima Noor',
      grNo: '2021-EL/F-009',
      email: '-',
      program: 'DAE Electronics Technology (F)',
      batch: 'EL-2021-MOR',
      cnic: '-',
      admission: '-',
      phone: '923214 778 903'),
];

const List<EmployeeRecord> employeeDB = [
  EmployeeRecord(
      name: 'Shahid Jamil',
      empId: '0028',
      programType: 'DAE',
      scaleType: 'Non Engineering',
      department: 'GENERAL',
      staffType: 'Non-Teaching',
      email: 'shahid@ait.com',
      phone: '0333-2109215'),
  EmployeeRecord(
      name: 'Syed Rehan Ali',
      empId: '0001',
      programType: 'DAE',
      scaleType: 'Non Engineering',
      department: 'BASIC SCIENCE',
      staffType: 'Teaching',
      email: 'srali@aligarh.edu.pk',
      phone: '03002260200'),
  EmployeeRecord(
      name: 'Syeda Javeria Gulshan',
      empId: '0008',
      programType: 'DAE',
      scaleType: 'Non Engineering',
      department: 'BASIC SCIENCE',
      staffType: 'Teaching',
      email: 'sjaveria@aligarh.edu.pk',
      phone: '0301-2244567'),
];

const List<NoticeItem> adminNotices = [
  NoticeItem('24/06/2025', 'Notice For: All',
      '3rd year Annual Practical Exam 2025 will commence Thursday 26/06/25. Refer to schedule on portal.'),
  NoticeItem('24/04/2025', 'Notice For: Students',
      'Result based parent teacher meeting is scheduled on Sunday 4th May 2025.'),
];

const List<HolidayItem> holidays = [
  HolidayItem('24 Jul 2026', 'PROJECT EXHIBITION'),
  HolidayItem('25 Jun 2026', 'MUHARRAM UL HARAM'),
  HolidayItem('25 May 2026', 'Eid ul Adha 2026'),
  HolidayItem('01 May 2026', 'Labour Day'),
  HolidayItem('16 Mar 2026', 'Eid ul Fitr 2026'),
];

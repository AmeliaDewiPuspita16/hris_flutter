import 'approve_request_item.dart';

/// Data contoh daftar permintaan yang menunggu approve/reject tim IT.
class ApproveRequestDemoData {
  ApproveRequestDemoData._();

  static List<ApproveRequestItem> items() => [
        const ApproveRequestItem(
          id: 'appr-1',
          requesterName: 'Rika Susila Susanti',
          department: 'AML',
          description:
              'Setting zoom meeting persiapan FGD di ruang Srikandi jam 14.00',
        ),
        const ApproveRequestItem(
          id: 'appr-2',
          requesterName: 'Rika Susila Susanti',
          department: 'AML',
          description:
              'Request perangkat Camera, HDMI untuk zoom meeting di TV ruang AML',
        ),
        const ApproveRequestItem(
          id: 'appr-3',
          requesterName: 'Andang Eka Putra',
          department: 'AML',
          description: 'Perbaikan validasi ukuran upload dokumen',
        ),
        const ApproveRequestItem(
          id: 'appr-4',
          requesterName: 'Frida Khaerani',
          department: 'HR & GA',
          description:
              'Siapkan sound system, proyektor, 2 mic & 1 pointer untuk kegiatan KISS',
        ),
      ];
}
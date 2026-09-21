import 'est_maintenance_plan.dart';
import 'est_request_item.dart';
import 'est_request_status.dart';
import 'est_request_type.dart';
import 'est_work_detail.dart';

/// Data contoh "EST Work Order"
class EstRequestDemoData {
  EstRequestDemoData._();

  static List<EstRequestItem> items() => [
        const EstRequestItem(
          id: 'est-1',
          requesterName: 'Reza Zulfiansyah',
          department: 'EVD',
          type: EstRequestType.project,
          location: 'BIEV - ST 2C',
          description: 'Dear Est team, mohon bantuannya untuk menindak '
              'lanjuti permintaan pengecatan unit studio 2C terimakasih.',
          date: '17 Sep 2026',
          status: EstRequestStatus.maintenancePlan,
          plan: EstMaintenancePlan(
            workingMethod: 'Skrap, pengecatan',
            materialAndTools: 'Alat dan material',
            approvalNote: 'Wait Approval Section Head',
          ),
        ),
        const EstRequestItem(
          id: 'est-2',
          requesterName: 'Vittauli Situmorang',
          department: 'HR & GA',
          type: EstRequestType.repair,
          location: 'Blok 3 unit 8',
          description: '1. 1 lampu toilet yang putus 2. AC kamar nomor 6 '
              'dorm blok 3 unit 8 mati sendiri',
          date: '17 Sep 2026',
          status: EstRequestStatus.onWaiting,
        ),
        const EstRequestItem(
          id: 'est-3',
          requesterName: 'Rachmananda',
          department: 'BDD',
          type: EstRequestType.project,
          location: 'Klinik Prodia',
          description: 'Penambahan ramp dan door closer',
          date: '16 Sep 2026',
          status: EstRequestStatus.maintenancePlan,
          plan: EstMaintenancePlan(
            workingMethod: 'Pemasangan ramp & door closer',
            materialAndTools: 'Besi ramp, door closer, alat pasang',
            approvalNote: 'Wait Approval Section Head',
          ),
        ),
        const EstRequestItem(
          id: 'est-4',
          requesterName: 'Erick Demiska Perwira',
          department: 'CRS',
          type: EstRequestType.repair,
          location: 'LOT 20A',
          description: 'Dear Tim Estate, mohon bantu untuk pengecekan dan '
              'perbaikan drainase tersumbat di depan lot 20A, air parit '
              'tidak mengalir kepembuangan sebagaimana semestinya. '
              'Terimakasih.',
          date: '16 Sep 2026',
          status: EstRequestStatus.onWaiting,
        ),
        const EstRequestItem(
          id: 'est-5',
          requesterName: 'Dini Dwi Pratiwi',
          department: 'HSE',
          type: EstRequestType.project,
          location: 'Pujasera area, lapangan basket, bola, volly dll',
          description: 'Dear pak tris, mohon support untuk lampu dan '
              'listrik untuk persiapan annual game 2026. terimakasih',
          date: '16 Sep 2026',
          status: EstRequestStatus.waitApprovalHod,
          plan: EstMaintenancePlan(
            workingMethod: 'Instalasi lampu sorot & jalur listrik sementara',
            materialAndTools: 'Lampu sorot, kabel NYY, stop kontak outdoor',
            approvalNote: 'Wait Approval Section Head',
          ),
        ),
        const EstRequestItem(
          id: 'est-6',
          requesterName: 'Aditya Yudha Pratama',
          department: 'ITM',
          type: EstRequestType.repair,
          location: 'ITM Room, Wisma BIE',
          description: 'Dear Utilities Team, mohon bantuannya karena AC '
              'kami sering mati sendiri, padahal timer sudah kami non '
              'aktifkan',
          date: '15 Sep 2026',
          status: EstRequestStatus.onWaiting,
        ),
        const EstRequestItem(
          id: 'est-7',
          requesterName: 'Vittauli Situmorang',
          department: 'HR & GA',
          type: EstRequestType.repair,
          location: 'blok 3 unit 8',
          description: 'Lampu lorong mati dan lampu kitchen kedip-kedip '
              '(jenis lampu bulat)',
          date: '24 Aug 2026',
          status: EstRequestStatus.waitVerifyUser,
          plan: EstMaintenancePlan(
            workingMethod: 'Penggantian lampu dengan yang baru',
            materialAndTools: 'Tangga, lampu',
            approvalNote: 'Approved by Trisanto Nadapdap',
          ),
          workDetail: EstWorkDetail(
            duration: '1 Day',
            manPower: '1',
            approvedBy: 'Trisanto Nadapdap',
            dateApprove: '28 Aug 2026',
            startDate: '28 Aug 2026',
            endDate: '28 Aug 2026',
            workBy: 'Legiono',
            verification: 'Wait Verification',
          ),
        ),
      ];
}

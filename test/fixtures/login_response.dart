/// Contoh respons `POST /api/login` dari BIIE Portal.
///
/// Struktur dan nama field-nya persis seperti respons sungguhan, tapi
/// access_token dan fcm_token sengaja diganti nilai palsu — rahasia tidak
/// boleh ikut tersimpan di repositori.
Map<String, dynamic> loginResponseEnvelope() => {
      'code': 200,
      'status': 'success',
      'message': 'Authenticated',
      'data': loginResponseData(),
    };

Map<String, dynamic> loginResponseData() => {
      'access_token': '9999|TOKENPALSUUNTUKPENGUJIANSAJA0000000000',
      'token_type': 'Bearer',
      'user': loginResponseUser(),
    };

Map<String, dynamic> loginResponseUser() => {
      'id': 3,
      'name': 'Ari Putra',
      'email': 'ariputra@biie.co.id',
      'email_verified_at': null,
      'fcm_token': 'fcm-token-palsu-untuk-pengujian',
      'created_at': '2022-08-24T01:36:37.000000Z',
      'updated_at': '2026-09-08T01:32:55.000000Z',
      'id_department': 18,
      'id_sub_department': 0,
      'no_hp': '082269859515',
      'nik': '0774',
      'section': 'IT Solution',
      'date_of_birth': '1991-11-21',
      'gender': 'male',
      'last_login_at': '2026-09-08T01:32:55.000000Z',
      'last_login_ip': '175.111.116.154',
      'image': 'ElAfRcrE0ZRtHsLm5PvIqGo32hIc0n3OrlmC8lsz.jpg',
      'status': 1,
      'active_status': 0,
      'avatar': 'avatar.png',
      'dark_mode': 0,
      'messenger_color': null,
      'roles': [
        _role(8, 'gmo'),
        _role(16, 'est building'),
        _role(19, 'it media'),
        _role(48, 'daily-worker'),
        _role(54, 'Foodcost-Admin'),
        _role(56, 'epro-requestor'),
        _role(61, 'epro-approver-finance'),
        _role(67, 'est iot meter reading email report'),
      ],
    };

Map<String, dynamic> _role(int id, String name) => {
      'id': id,
      'name': name,
      'guard_name': 'web',
      'created_at': '2022-11-15T07:29:26.000000Z',
      'updated_at': '2022-11-15T07:29:26.000000Z',
      'pivot': {
        'model_id': 3,
        'role_id': id,
        'model_type': 'App\\Models\\User',
      },
    };

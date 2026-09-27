insert into users (
    id, login_id, password, name, phone, role, active, created_at, updated_at
) values
      (1, 'superadmin', '$2a$10$nzp33ooDbQ0j7g/IMREzW.pq8tJU0te7Qg19hAejPHXp7IMqMGXxS', '최고관리자', '010-9999-9999', 'SUPER_ADMIN', true, now(), now()),
      (2, 'admin', '$2a$10$nzp33ooDbQ0j7g/IMREzW.pq8tJU0te7Qg19hAejPHXp7IMqMGXxS', '관리자', '010-0000-0000', 'ADMIN', true, now(), now()),
      (3, 'employee01', '$2a$10$nzp33ooDbQ0j7g/IMREzW.pq8tJU0te7Qg19hAejPHXp7IMqMGXxS', '홍길동', '010-1111-1111', 'EMPLOYEE', true, now(), now())
    on duplicate key update
                         login_id = values(login_id),
                         password = values(password),
                         name = values(name),
                         phone = values(phone),
                         role = values(role),
                         active = values(active),
                         updated_at = now();

insert into work_sites (
    id, name, address, description, active, created_at, updated_at
) values (
             1,
             '101동 외벽 페인트 작업',
             '서울시 테스트구 테스트로 101',
             '출석 서비스 테스트용 작업 현장',
             true,
             now(),
             now()
         )
    on duplicate key update
                         name = values(name),
                         address = values(address),
                         description = values(description),
                         active = values(active),
                         updated_at = now();

insert into beacons (
    id, work_site_id, uuid, major, minor, name, rssi_threshold, active, created_at, updated_at
) values (
             1,
             1,
             'fda50693-a4e2-4fb1-afcf-c6eb07647825',
             101,
             1,
             '101동 입구 비콘',
             -75,
             true,
             now(),
             now()
         )
    on duplicate key update
                         work_site_id = values(work_site_id),
                         uuid = values(uuid),
                         major = values(major),
                         minor = values(minor),
                         name = values(name),
                         rssi_threshold = values(rssi_threshold),
                         active = values(active),
                         updated_at = now();

insert into work_schedules (
    id, work_site_id, work_date, start_time, end_time,
    late_grace_minutes, early_leave_grace_minutes, created_at, updated_at
) values (
             1,
             1,
             current_date,
             '08:00:00',
             '17:00:00',
             5,
             5,
             now(),
             now()
         )
    on duplicate key update
                         work_site_id = values(work_site_id),
                         work_date = current_date,
                         start_time = values(start_time),
                         end_time = values(end_time),
                         late_grace_minutes = values(late_grace_minutes),
                         early_leave_grace_minutes = values(early_leave_grace_minutes),
                         updated_at = now();

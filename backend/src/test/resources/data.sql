insert into users (
    id,
    login_id,
    password,
    name,
    phone,
    role,
    active,
    created_at,
    updated_at
) values
    (1, 'admin', '$2a$10$nzp33ooDbQ0j7g/IMREzW.pq8tJU0te7Qg19hAejPHXp7IMqMGXxS', '관리자', '010-0000-0000', 'ADMIN', true, '2026-08-08 00:00:00', '2026-08-08 00:00:00'),
    (2, 'employee01', '$2a$10$nzp33ooDbQ0j7g/IMREzW.pq8tJU0te7Qg19hAejPHXp7IMqMGXxS', '홍길동', '010-1111-1111', 'EMPLOYEE', true, '2026-08-08 00:00:00', '2026-08-08 00:00:00');

insert into work_sites (
    id,
    name,
    address,
    description,
    active,
    created_at,
    updated_at
) values (
    1,
    '101동 외벽 페인트 작업',
    '서울시 테스트구 테스트로 101',
    '출석 서비스 테스트용 작업 현장',
    true,
    '2026-08-08 00:00:00',
    '2026-08-08 00:00:00'
);

insert into beacons (
    id,
    work_site_id,
    uuid,
    major,
    minor,
    name,
    rssi_threshold,
    active,
    created_at,
    updated_at
) values (
    1,
    1,
    'fda50693-a4e2-4fb1-afcf-c6eb07647825',
    101,
    1,
    '101동 입구 비콘',
    -75,
    true,
    '2026-08-08 00:00:00',
    '2026-08-08 00:00:00'
);

insert into work_schedules (
    id,
    work_site_id,
    work_date,
    start_time,
    end_time,
    late_grace_minutes,
    early_leave_grace_minutes,
    created_at,
    updated_at
) values (
    1,
    1,
    '2026-08-08',
    '08:00:00',
    '17:00:00',
    5,
    5,
    '2026-08-08 00:00:00',
    '2026-08-08 00:00:00'
);

insert into employee_project_pay_setting (
    id,
    employee_id,
    work_site_id,
    daily_wage,
    tax_rate,
    active,
    created_at,
    updated_at
) values (
             1,
             2,
             1,
             150000,
             3.30,
             true,
             '2026-08-08 00:00:00',
             '2026-08-08 00:00:00'
         );

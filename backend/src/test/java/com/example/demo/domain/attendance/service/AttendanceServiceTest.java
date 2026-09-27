package com.example.demo.domain.attendance.service;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.example.demo.domain.attendance.AttendanceStatus;
import com.example.demo.domain.attendance.dto.AttendanceCheckRequest;
import com.example.demo.domain.attendance.dto.AttendanceCheckResponse;
import java.math.BigDecimal;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneId;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Primary;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

@ActiveProfiles("test")
@SpringBootTest
@Transactional
class AttendanceServiceTest {

    private static final ZoneId ZONE_ID = ZoneId.of("Asia/Seoul");

    @Autowired
    private AttendanceService attendanceService;

    @Autowired
    @Qualifier("testClock")
    private MutableClock clock;

    @Test
    void checkIn_createsNormalAttendanceRecord() {
        clock.setDateTime(LocalDateTime.of(2026, 8, 8, 8, 3));

        AttendanceCheckResponse response = attendanceService.checkIn(2L, validRequest(-68));

        assertNotNull(response.recordId());
        assertEquals(AttendanceStatus.NORMAL, response.status());
        assertEquals(LocalDateTime.of(2026, 8, 8, 8, 3), response.checkedInAt());
        assertEquals("101동 외벽 페인트 작업", response.siteName());
    }

    @Test
    void checkIn_afterGraceMinutes_isLate() {
        clock.setDateTime(LocalDateTime.of(2026, 8, 8, 8, 6));

        AttendanceCheckResponse response = attendanceService.checkIn(2L, validRequest(-68));

        assertEquals(AttendanceStatus.LATE, response.status());
    }

    @Test
    void checkIn_whenBeaconSignalIsTooWeak_throwsException() {
        clock.setDateTime(LocalDateTime.of(2026, 8, 8, 8, 3));

        assertThrows(
                IllegalArgumentException.class,
                () -> attendanceService.checkIn(2L, validRequest(-80))
        );
    }

    @Test
    void checkOut_beforeEarlyLeaveLimit_isEarlyLeave() {
        clock.setDateTime(LocalDateTime.of(2026, 8, 8, 8, 3));
        attendanceService.checkIn(2L, validRequest(-68));

        clock.setDateTime(LocalDateTime.of(2026, 8, 8, 16, 50));
        AttendanceCheckResponse response = attendanceService.checkOut(2L, validRequest(-69));

        assertEquals(AttendanceStatus.EARLY_LEAVE, response.status());
        assertEquals(LocalDateTime.of(2026, 8, 8, 16, 50), response.checkedOutAt());
    }

    private AttendanceCheckRequest validRequest(Integer rssi) {
        return new AttendanceCheckRequest(
                "fda50693-a4e2-4fb1-afcf-c6eb07647825",
                101,
                1,
                rssi,
                "test-device-001",
                BigDecimal.valueOf(37.5665),
                BigDecimal.valueOf(126.9780)
        );
    }

    @TestConfiguration
    static class TestClockConfig {

        @Bean
        @Primary
        MutableClock testClock() {
            return new MutableClock(ZONE_ID);
        }
    }

    static class MutableClock extends Clock {

        private final ZoneId zoneId;
        private Instant instant;

        MutableClock(ZoneId zoneId) {
            this.zoneId = zoneId;
            setDateTime(LocalDateTime.of(2026, 8, 8, 0, 0));
        }

        void setDateTime(LocalDateTime dateTime) {
            this.instant = dateTime.atZone(zoneId).toInstant();
        }

        @Override
        public ZoneId getZone() {
            return zoneId;
        }

        @Override
        public Clock withZone(ZoneId zone) {
            return new MutableClock(zone);
        }

        @Override
        public Instant instant() {
            return instant;
        }
    }
}

package com.example.demo.domain.beacon;

import com.example.demo.domain.worksite.WorkSite;
import com.example.demo.global.common.entity.BaseTimeEntity;
import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@Entity
@Table(
        name = "beacons",
        indexes = {
                @Index(name = "idx_beacons_identifier", columnList = "uuid, major, minor")
        },
        uniqueConstraints = {
                @UniqueConstraint(name = "uk_beacons_identifier", columnNames = {"uuid", "major", "minor"})
        }
)
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class Beacon extends BaseTimeEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "work_site_id", nullable = false)
    private WorkSite workSite;

    @Column(nullable = false, length = 36)
    private String uuid;

    @Column(name = "major", nullable = false)
    private Integer major;

    @Column(name = "minor", nullable = false)
    private Integer minor;

    @Column(nullable = false, length = 100)
    private String name;

    @Column(name = "rssi_threshold", nullable = false)
    private Integer rssiThreshold;

    @Column(nullable = false)
    private boolean active;

    @Builder
    private Beacon(
            WorkSite workSite,
            String uuid,
            Integer major,
            Integer minor,
            String name,
            Integer rssiThreshold,
            Boolean active
    ) {
        this.workSite = workSite;
        this.uuid = uuid;
        this.major = major;
        this.minor = minor;
        this.name = name;
        this.rssiThreshold = rssiThreshold;
        this.active = active == null || active;
    }

    public void update(
            WorkSite workSite,
            String uuid,
            Integer major,
            Integer minor,
            String name,
            Integer rssiThreshold
    ) {
        this.workSite = workSite;
        this.uuid = uuid;
        this.major = major;
        this.minor = minor;
        this.name = name;
        this.rssiThreshold = rssiThreshold;
    }

    public void deactivate() {
        this.active = false;
    }

    public boolean isInRange(Integer rssi){
        return rssi >= this.rssiThreshold;
    }
}

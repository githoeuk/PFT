package com.example.demo.domain.beacon;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface BeaconRepository extends JpaRepository<Beacon, Long> {
    Optional<Beacon> findByUuidAndMajorAndMinorAndActiveTrue(
            String uuid,
            Integer major,
            Integer minor
            );

    List<Beacon> findByWorkSite_IdAndActiveTrueOrderByCreatedAtDesc(Long workSiteId);

    Optional<Beacon> findByIdAndActiveTrue(Long id);

    boolean existsByUuidAndMajorAndMinor(
            String uuid,
            Integer major,
            Integer minor
    );

    boolean existsByUuidAndMajorAndMinorAndIdNot(
            String uuid,
            Integer major,
            Integer minor,
            Long beaconId
    );
}

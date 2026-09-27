package com.example.demo.domain.worksite;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface WorkSiteRepository extends JpaRepository<WorkSite, Long> {

    List<WorkSite> findByActiveTrueOrderByCreatedAtDesc();

    Optional<WorkSite> findByIdAndActiveTrue(Long id);

    boolean existsByName(String name);

    List<WorkSite> findByNameContainingAndActiveTrue(String keyword);

}

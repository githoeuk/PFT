package com.example.demo.domain.worksite;

import com.example.demo.global.common.entity.BaseTimeEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.AccessLevel;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@Entity
@Table(name = "work_sites")
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class WorkSite extends BaseTimeEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 100)
    private String name;

    @Column(nullable = false, length = 255)
    private String address;

    @Column(length = 1000)
    private String description;

    @Column(nullable = false)
    private boolean active;

    @Builder
    private WorkSite(String name, String address, String description, Boolean active) {
        this.name = name;
        this.address = address;
        this.description = description;
        this.active = active == null || active;
    }

    public void update(String name, String address, String description){
        this.name = name;
        this.address = address;
        this.description = description;
    }

    public void deactivate(){
        this.active = false;
    }
}

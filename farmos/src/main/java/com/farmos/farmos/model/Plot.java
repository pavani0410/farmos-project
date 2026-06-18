package com.farmos.farmos.model;

import jakarta.persistence.*;
import lombok.Data;

@Data
@Entity
@Table(name = "plots")
public class Plot {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String name;
    private String soilType;
    private Double areaM2;
    private Double areaAcres;

    // stores the polygon points as a JSON string
    // e.g. "[{x:100,y:50},{x:200,y:50},{x:150,y:120}]"
    // @Column(columnDefinition) tells PostgreSQL to use TEXT type
    // because the string can be very long
    @Column(columnDefinition = "TEXT")
    private String polygonPoints;

    // stores digitizer metadata as JSON, including the source sketch image and overlay data
    @Column(columnDefinition = "TEXT")
    private String digitizedDiagram;

    // links this plot to a farm
    @ManyToOne
    @JoinColumn(name = "farm_id")
    private Farm farm;
}

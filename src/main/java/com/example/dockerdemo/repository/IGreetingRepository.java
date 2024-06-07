package com.example.dockerdemo.repository;

import com.example.dockerdemo.model.Greeting;
import org.springframework.data.jpa.repository.JpaRepository;

public interface IGreetingRepository extends JpaRepository<Greeting, String> {
}

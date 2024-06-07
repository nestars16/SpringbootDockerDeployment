package com.example.dockerdemo.controllers;

import com.example.dockerdemo.model.Greeting;
import com.example.dockerdemo.repository.IGreetingRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController("/greeting")
public class GreetingController {

    private final IGreetingRepository greetingRepository;

    public GreetingController(IGreetingRepository greetingRepository) {
        this.greetingRepository = greetingRepository;
    }

    @GetMapping("/{id}/basic")
    public ResponseEntity<String> simpleGreeting(@PathVariable String id) {
        var greeting = greetingRepository.findById(id);
        return greeting.map(value -> ResponseEntity.ok("<h1>" + value.getText() + "</h1>")).orElseGet(() -> ResponseEntity.notFound().build());
    }

    @GetMapping("/{id}/fancy")
    public ResponseEntity<String> fancyGreeting(@PathVariable String id) {
        var greeting = greetingRepository.findById(id);

        return greeting.map(value -> ResponseEntity.ok(
                "<div style=\"width:100%;height:100%;background-color:#f0f0f0;display:flex;justify-content:center;align-items:center\">" +
                        "<h1 class=\"font-size:1.5rem;font-weight:bold;\">" +
                        value.getText() +
                        "</h1></div>"
        )).orElseGet(() -> ResponseEntity.notFound().build());

    }

    @PostMapping("/create")
    public ResponseEntity<Greeting> createGreeting(Greeting greeting) {
        return ResponseEntity.ok(greetingRepository.save(greeting));
    }
}

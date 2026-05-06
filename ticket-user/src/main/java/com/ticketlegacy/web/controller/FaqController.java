package com.ticketlegacy.web.controller;

import com.ticketlegacy.domain.Faq;
import com.ticketlegacy.service.FaqService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;

import java.util.List;

@Controller
public class FaqController {

    @Autowired
    private FaqService faqService;

    @GetMapping("/support/faq")
    public String faq(@RequestParam(required = false) String category, Model model) {
        List<Faq> faqs = faqService.getActiveFaqs(category);
        List<String> categories = faqService.getCategories();
        
        model.addAttribute("faqs", faqs);
        model.addAttribute("categories", categories);
        model.addAttribute("currentCategory", category);
        
        return "support/faq";
    }
}

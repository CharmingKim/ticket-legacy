package com.ticketlegacy.web.controller;

import com.ticketlegacy.domain.Notice;
import com.ticketlegacy.service.NoticeService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestParam;

import javax.servlet.http.HttpServletRequest;
import java.util.List;

@Controller
public class NoticeController {

    @Autowired
    private NoticeService noticeService;

    @GetMapping("/notice/list")
    public String list(@RequestParam(defaultValue = "1") int page,
                       @RequestParam(required = false) String type,
                       Model model) {
        List<Notice> list = noticeService.findAll(type, page);
        int total = noticeService.countAll(type);
        
        model.addAttribute("notices", list);
        model.addAttribute("total", total);
        model.addAttribute("currentPage", page);
        model.addAttribute("currentType", type);
        model.addAttribute("totalPages", (int) Math.ceil((double) total / 20));
        
        return "notice/list";
    }

    @GetMapping("/notice/detail/{id}")
    public String detail(@PathVariable Long id, Model model) {
        Notice notice = noticeService.findById(id);
        model.addAttribute("notice", notice);
        return "notice/detail";
    }
}

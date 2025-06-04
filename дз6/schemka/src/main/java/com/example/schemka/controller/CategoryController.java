package com.example.schemka.controller;

import com.example.schemka.dto.CategoryCreateRequest;
import com.example.schemka.entity.Category;
import com.example.schemka.service.CategoryService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/categories")
@Tag(name = "Categories", description = "API для управления категориями")
public class CategoryController {

    @Autowired
    private CategoryService categoryService;

    @PostMapping
    @Operation(summary = "Создать новую категорию", description = "Создает новую категорию товаров")
    public ResponseEntity<Category> createCategory(@RequestBody CategoryCreateRequest request) {
        Category category = categoryService.createCategory(request);
        return ResponseEntity.ok(category);
    }
}

package com.example.schemka.service;

import com.example.schemka.dto.CategoryCreateRequest;
import com.example.schemka.entity.Category;
import com.example.schemka.repository.CategoryRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class CategoryService {

    @Autowired
    private CategoryRepository categoryRepository;

    public Category createCategory(CategoryCreateRequest request) {
        Category category = new Category(
                request.getName(),
                request.getDescription(),
                request.getParentId(),
                request.getImageUrl());
        return categoryRepository.save(category);
    }

    public Category findById(Long id) {
        return categoryRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Category not found with id: " + id));
    }
}

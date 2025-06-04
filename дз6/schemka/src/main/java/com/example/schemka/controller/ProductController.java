package com.example.schemka.controller;

import com.example.schemka.dto.ProductCreateRequest;
import com.example.schemka.dto.ProductUpdateRequest;
import com.example.schemka.dto.ProductWithCategoryResponse;
import com.example.schemka.entity.Product;
import com.example.schemka.service.ProductService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/products")
@Tag(name = "Products", description = "API для управления товарами")
public class ProductController {

    @Autowired
    private ProductService productService;

    @PostMapping
    @Operation(summary = "Создать товар", description = "Создает новый товар")
    public ResponseEntity<Product> createProduct(@RequestBody ProductCreateRequest request) {
        Product product = productService.createProduct(request);
        return ResponseEntity.ok(product);
    }

    @PutMapping("/{id}")
    @Operation(summary = "Редактировать товар", description = "Обновляет поля существующего товара")
    public ResponseEntity<Product> updateProduct(@PathVariable Long id, @RequestBody ProductUpdateRequest request) {
        Product product = productService.updateProduct(id, request);
        return ResponseEntity.ok(product);
    }

    @PutMapping("/{productId}/category/{categoryId}")
    @Operation(summary = "Привязать товар к категории", description = "Привязывает существующий товар к категории")
    public ResponseEntity<Product> assignCategory(@PathVariable Long productId, @PathVariable Long categoryId) {
        Product product = productService.assignCategory(productId, categoryId);
        return ResponseEntity.ok(product);
    }

    @GetMapping("/with-categories")
    @Operation(summary = "Получить все товары с категориями", description = "Возвращает список всех товаров с названиями их категорий")
    public ResponseEntity<List<ProductWithCategoryResponse>> getAllProductsWithCategories() {
        List<ProductWithCategoryResponse> products = productService.getAllProductsWithCategories();
        return ResponseEntity.ok(products);
    }
}

package com.example.schemka.service;

import com.example.schemka.dto.ProductCreateRequest;
import com.example.schemka.dto.ProductUpdateRequest;
import com.example.schemka.dto.ProductWithCategoryResponse;
import com.example.schemka.entity.Category;
import com.example.schemka.entity.Product;
import com.example.schemka.repository.ProductRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import java.util.List;

@Service
public class ProductService {

    @Autowired
    private ProductRepository productRepository;

    @Autowired
    private CategoryService categoryService;

    public Product createProduct(ProductCreateRequest request) {
        Category category = null;
        if (request.getCategoryId() != null) {
            category = categoryService.findById(request.getCategoryId());
        }
        Product product = new Product(
                request.getName(),
                request.getDescription(),
                request.getPrice(),
                request.getStockQuantity(),
                request.getImageUrl(),
                category);
        return productRepository.save(product);
    }

    public Product updateProduct(Long id, ProductUpdateRequest request) {
        Product product = productRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Product not found with id: " + id));

        if (request.getName() != null) {
            product.setName(request.getName());
        }
        if (request.getDescription() != null) {
            product.setDescription(request.getDescription());
        }
        if (request.getPrice() != null) {
            product.setPrice(request.getPrice());
        }
        if (request.getStockQuantity() != null) {
            product.setStockQuantity(request.getStockQuantity());
        }
        if (request.getImageUrl() != null) {
            product.setImageUrl(request.getImageUrl());
        }
        if (request.getCategoryId() != null) {
            Category category = categoryService.findById(request.getCategoryId());
            product.setCategory(category);
        }

        return productRepository.save(product);
    }

    public Product assignCategory(Long productId, Long categoryId) {
        Product product = productRepository.findById(productId)
                .orElseThrow(() -> new RuntimeException("Product not found with id: " + productId));
        Category category = categoryService.findById(categoryId);

        product.setCategory(category);
        return productRepository.save(product);
    }

    public List<ProductWithCategoryResponse> getAllProductsWithCategories() {
        return productRepository.findAllProductsWithCategories();
    }
}

package com.example.schemka.repository;

import com.example.schemka.entity.Product;
import com.example.schemka.dto.ProductWithCategoryResponse;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface ProductRepository extends JpaRepository<Product, Long> {

    @Query("SELECT new com.example.schemka.dto.ProductWithCategoryResponse(p.id, p.name, p.description, p.price, p.stockQuantity, p.imageUrl, c.name) FROM Product p JOIN p.category c")
    List<ProductWithCategoryResponse> findAllProductsWithCategories();
}

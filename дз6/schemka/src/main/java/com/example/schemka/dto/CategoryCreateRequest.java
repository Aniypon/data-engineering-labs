package com.example.schemka.dto;

public class CategoryCreateRequest {
    private String name;
    private String description;
    private Long parentId;
    private String imageUrl;

    public CategoryCreateRequest() {
    }

    public CategoryCreateRequest(String name, String description, Long parentId, String imageUrl) {
        this.name = name;
        this.description = description;
        this.parentId = parentId;
        this.imageUrl = imageUrl;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public Long getParentId() {
        return parentId;
    }

    public void setParentId(Long parentId) {
        this.parentId = parentId;
    }

    public String getImageUrl() {
        return imageUrl;
    }

    public void setImageUrl(String imageUrl) {
        this.imageUrl = imageUrl;
    }
}

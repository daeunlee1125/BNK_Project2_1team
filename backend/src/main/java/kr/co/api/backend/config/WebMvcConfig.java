package kr.co.api.backend.config;

import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import java.nio.file.Paths;



@RequiredArgsConstructor
@Configuration
public class WebMvcConfig implements WebMvcConfigurer {

    private final FilePathConfig filePathConfig;

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {

        // -------------------------------------------------
        // AI PDF
        // -------------------------------------------------
        registry.addResourceHandler("/pdf_ai/**")
                .addResourceLocations("file:/app/uploads/pdf_ai/");

        // -------------------------------------------------
        // 약관 PDF
        // -------------------------------------------------
        String termsPath = filePathConfig.getPdfTermsPath(); // /app/uploads/terms
        String termsLocation = Paths.get(termsPath).toUri().toString();
        if (!termsLocation.endsWith("/")) {
            termsLocation += "/";
        }

        //  backend 포함 경로
        registry.addResourceHandler("/backend/uploads/terms/**")
                .addResourceLocations(termsLocation);

        //  backend 없는 경로 (지금 에러의 원인)
        registry.addResourceHandler("/uploads/terms/**")
                .addResourceLocations(termsLocation);

        // -------------------------------------------------
        // 상품설명서 PDF
        // -------------------------------------------------
        String productPath = filePathConfig.getPdfProductsPath(); // /app/uploads/pdf_products
        String productLocation = Paths.get(productPath).toUri().toString();
        if (!productLocation.endsWith("/")) {
            productLocation += "/";
        }

        //  backend 포함
        registry.addResourceHandler("/backend/uploads/products/**")
                .addResourceLocations(productLocation);

        //  backend 없는 경우 대비 (권장)
        registry.addResourceHandler("/uploads/products/**")
                .addResourceLocations(productLocation);
    }
}

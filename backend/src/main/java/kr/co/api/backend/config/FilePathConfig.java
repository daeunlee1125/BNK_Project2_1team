package kr.co.api.backend.config;

import jakarta.annotation.PostConstruct;
import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

@Configuration
@ConfigurationProperties(prefix = "file.upload")
@Data
public class FilePathConfig {
    private String pdfTermsPath;
    private String pdfProductsPath;


    //pdf 서버에 제대로 들어갔는지 확인
    @PostConstruct
    public void logPaths() {
        System.out.println("▶ pdfTermsPath = " + pdfTermsPath);
        System.out.println("▶ pdfProductsPath = " + pdfProductsPath);
    }
}


package com.guilin.news.servlet;

import javax.servlet.Filter;
import javax.servlet.FilterChain;
import javax.servlet.FilterConfig;
import javax.servlet.ServletException;
import javax.servlet.ServletRequest;
import javax.servlet.ServletResponse;
import javax.servlet.annotation.WebFilter;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;

/**
 * 统一为所有 {@code /api/*} 请求设置 CORS 头并处理 OPTIONS 预检。
 *
 * <p>取代重构前在每个 Servlet 方法里重复设置 CORS 头的做法。</p>
 *
 * <p>注意：显式实现 {@code init}/{@code destroy}。运行时容器 Tomcat 7 为 Servlet 3.0，
 * 其 {@code Filter} 接口未提供这些方法的默认实现（Servlet 4.0 才有），不实现会导致
 * {@code AbstractMethodError}。</p>
 */
@WebFilter("/api/*")
public class CorsFilter implements Filter {

    @Override
    public void init(FilterConfig filterConfig) {
        // 无需初始化
    }

    @Override
    public void doFilter(ServletRequest req, ServletResponse res, FilterChain chain)
            throws IOException, ServletException {
        HttpServletRequest request = (HttpServletRequest) req;
        HttpServletResponse response = (HttpServletResponse) res;

        response.setHeader("Access-Control-Allow-Origin", "*");
        response.setHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
        response.setHeader("Access-Control-Allow-Headers", "Content-Type");

        // 预检请求直接放行，不进入业务逻辑
        if ("OPTIONS".equalsIgnoreCase(request.getMethod())) {
            response.setStatus(HttpServletResponse.SC_OK);
            return;
        }

        chain.doFilter(req, res);
    }

    @Override
    public void destroy() {
        // 无需清理
    }
}

package com.guilin.news.servlet;

import com.google.gson.Gson;
import com.guilin.news.model.News;
import com.guilin.news.service.NewsService;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@WebServlet("/api/news/*")
public class ApiServlet extends HttpServlet {

    private NewsService newsService = new NewsService();
    private Gson gson = new Gson();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json;charset=UTF-8");
        response.setHeader("Access-Control-Allow-Origin", "*");

        PrintWriter out = response.getWriter();
        String pathInfo = request.getPathInfo();

        try {
            if (pathInfo == null || pathInfo.equals("/") || pathInfo.equals("/categories")) {
                Map<String, Object> result = new HashMap<>();
                result.put("success", true);
                result.put("categories", newsService.getAllCategories());
                out.print(gson.toJson(result));
                return;
            }

            if (pathInfo.equals("/detail")) {
                String url = request.getParameter("url");
                if (url == null || url.isEmpty()) {
                    response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                    Map<String, Object> error = new HashMap<>();
                    error.put("success", false);
                    error.put("message", "缺少 url 参数");
                    out.print(gson.toJson(error));
                    out.flush();
                    return;
                }

                try {
                    Map<String, String> detail = newsService.fetchNewsDetail(url);
                    Map<String, Object> result = new HashMap<>();
                    result.put("success", true);
                    result.put("detail", detail);
                    out.print(gson.toJson(result));
                } catch (Exception e) {
                    Map<String, Object> result = new HashMap<>();
                    result.put("success", false);
                    result.put("message", "获取详情失败: " + e.getMessage());
                    result.put("url", url);
                    out.print(gson.toJson(result));
                }
                out.flush();
                return;
            }

            String category = pathInfo.substring(1);
            String categoryName = NewsService.getCategoryName(category);
            List<News> newsList = newsService.fetchNews(category);

            Map<String, Object> result = new HashMap<>();
            result.put("success", true);
            result.put("category", category);
            result.put("categoryName", categoryName);
            result.put("newsList", newsList);
            out.print(gson.toJson(result));

        } catch (IllegalArgumentException e) {
            response.setStatus(HttpServletResponse.SC_NOT_FOUND);
            Map<String, Object> error = new HashMap<>();
            error.put("success", false);
            error.put("message", "未知的新闻分类");
            out.print(gson.toJson(error));
        } catch (IOException e) {
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            Map<String, Object> error = new HashMap<>();
            error.put("success", false);
            error.put("message", "获取新闻失败: " + e.getMessage());
            out.print(gson.toJson(error));
        }

        out.flush();
    }
}

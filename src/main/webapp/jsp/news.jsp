<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${categoryName} - 桂林学院新闻中心</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <style>
        .news-item {
            transition: background-color 0.2s;
        }
        .news-item:hover {
            background-color: #f8f9fa;
        }
        .news-link {
            color: #333;
            text-decoration: none;
        }
        .news-link:hover {
            color: #667eea;
        }
    </style>
</head>
<body>
    <nav class="navbar navbar-expand-lg navbar-dark bg-dark">
        <div class="container">
            <a class="navbar-brand" href="${pageContext.request.contextPath}/news/">桂林学院新闻中心</a>
            <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarNav">
                <span class="navbar-toggler-icon"></span>
            </button>
            <div class="collapse navbar-collapse" id="navbarNav">
                <ul class="navbar-nav">
                    <c:forEach var="entry" items="${categories}">
                        <li class="nav-item">
                            <a class="nav-link ${entry.key == category ? 'active' : ''}" 
                               href="${pageContext.request.contextPath}/news/${entry.key}">
                                <c:choose>
                                    <c:when test="${entry.key == 'xxxw'}">校内新闻</c:when>
                                    <c:when test="${entry.key == 'xsdt'}">学术动态</c:when>
                                    <c:when test="${entry.key == 'gyrw'}">光荣入伍</c:when>
                                    <c:when test="${entry.key == 'mtgy'}">媒体关注</c:when>
                                </c:choose>
                            </a>
                        </li>
                    </c:forEach>
                </ul>
            </div>
        </div>
    </nav>

    <div class="container mt-4">
        <nav aria-label="breadcrumb">
            <ol class="breadcrumb">
                <li class="breadcrumb-item"><a href="${pageContext.request.contextPath}/news/">首页</a></li>
                <li class="breadcrumb-item active">${categoryName}</li>
            </ol>
        </nav>

        <h2 class="mb-4">${categoryName}</h2>

        <div class="card">
            <div class="list-group list-group-flush">
                <c:forEach var="news" items="${newsList}" varStatus="status">
                    <a href="${news.link}" target="_blank" class="list-group-item list-group-item-action news-item">
                        <div class="d-flex w-100 justify-content-between">
                            <h6 class="mb-1 news-link">${news.title}</h6>
                            <small class="text-muted">${news.date}</small>
                        </div>
                    </a>
                </c:forEach>
            </div>
        </div>

        <c:if test="${empty newsList}">
            <div class="alert alert-info mt-3">
                暂无新闻数据，请稍后再试。
            </div>
        </c:if>
    </div>

    <footer class="bg-dark text-white text-center py-3 mt-5">
        <p class="mb-0">桂林学院新闻中心 &copy; 2024</p>
    </footer>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>

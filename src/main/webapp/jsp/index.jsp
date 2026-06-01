<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>桂林学院新闻中心</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <style>
        body {
            background-color: #f5f5f5;
        }
        .hero {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 60px 0;
            margin-bottom: 40px;
        }
        .card {
            transition: transform 0.2s;
            cursor: pointer;
        }
        .card:hover {
            transform: translateY(-5px);
            box-shadow: 0 10px 20px rgba(0,0,0,0.1);
        }
    </style>
</head>
<body>
    <nav class="navbar navbar-expand-lg navbar-dark bg-dark">
        <div class="container">
            <a class="navbar-brand" href="${pageContext.request.contextPath}/news/">桂林学院新闻中心</a>
        </div>
    </nav>

    <div class="hero text-center">
        <div class="container">
            <h1 class="display-4">桂林学院新闻中心</h1>
            <p class="lead">实时获取校园最新新闻动态</p>
        </div>
    </div>

    <div class="container">
        <div class="row">
            <c:forEach var="entry" items="${categories}">
                <div class="col-md-6 col-lg-3 mb-4">
                    <div class="card h-100" onclick="location.href='${pageContext.request.contextPath}/news/${entry.key}'">
                        <div class="card-body text-center">
                            <h5 class="card-title">
                                <c:choose>
                                    <c:when test="${entry.key == 'xxxw'}">📰</c:when>
                                    <c:when test="${entry.key == 'xsdt'}">📚</c:when>
                                    <c:when test="${entry.key == 'gyrw'}">🎖️</c:when>
                                    <c:when test="${entry.key == 'mtgy'}">📺</c:when>
                                </c:choose>
                            </h5>
                            <h6 class="card-subtitle mb-2 text-muted">
                                <c:choose>
                                    <c:when test="${entry.key == 'xxxw'}">校内新闻</c:when>
                                    <c:when test="${entry.key == 'xsdt'}">学术动态</c:when>
                                    <c:when test="${entry.key == 'gyrw'}">光荣入伍</c:when>
                                    <c:when test="${entry.key == 'mtgy'}">媒体关注</c:when>
                                </c:choose>
                            </h6>
                            <p class="card-text small text-muted">点击查看最新内容</p>
                        </div>
                    </div>
                </div>
            </c:forEach>
        </div>
    </div>

    <footer class="bg-dark text-white text-center py-3 mt-5">
        <p class="mb-0">桂林学院新闻中心 &copy; 2024</p>
    </footer>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>

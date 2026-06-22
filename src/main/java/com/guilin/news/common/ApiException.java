package com.guilin.news.common;

/**
 * 业务异常，携带可直接返回给前端的可读信息。
 *
 * <p>用于表达"客户端请求有误"或"业务规则不满足"等可预期错误，
 * 由 Servlet 捕获后转成 {@link ApiResponse#fail(String)}。</p>
 */
public class ApiException extends RuntimeException {

    public ApiException(String message) {
        super(message);
    }

    public ApiException(String message, Throwable cause) {
        super(message, cause);
    }
}

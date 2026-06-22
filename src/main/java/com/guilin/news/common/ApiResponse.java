package com.guilin.news.common;

/**
 * 统一 API 响应封装。
 *
 * <p>序列化后结构为 {@code {success, data, message}}，与重构前各处手工拼装的
 * {@code HashMap} 完全一致，因此前端无需改动。</p>
 *
 * @param <T> 业务数据类型
 */
public class ApiResponse<T> {

    private final boolean success;
    private final T data;
    private final String message;

    private ApiResponse(boolean success, T data, String message) {
        this.success = success;
        this.data = data;
        this.message = message;
    }

    /** 成功响应，携带业务数据。 */
    public static <T> ApiResponse<T> ok(T data) {
        return new ApiResponse<>(true, data, null);
    }

    /** 失败响应，携带可读错误信息。 */
    public static <T> ApiResponse<T> fail(String message) {
        return new ApiResponse<>(false, null, message);
    }

    public boolean isSuccess() {
        return success;
    }

    public T getData() {
        return data;
    }

    public String getMessage() {
        return message;
    }
}

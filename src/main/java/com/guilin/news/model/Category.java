package com.guilin.news.model;

import com.guilin.news.config.AppConfig;
import com.guilin.news.common.ApiException;

import java.util.LinkedHashMap;
import java.util.Map;

/**
 * 新闻分类的单一事实来源。
 *
 * <p>重构前分类信息以 {@code CATEGORY_MAP}（key→列表页 URL）与
 * {@code getCategoryName}（key→显示名）两套并行结构维护，容易不一致。
 * 此处合并为枚举，每个分类同时持有 key、显示名与列表页 URL。</p>
 */
public enum Category {

    XXXW("xxxw", "桂院要闻", AppConfig.BASE_URL + "/xwzx/xxxw.htm"),
    XSDT("xsdt", "学术动态", AppConfig.BASE_URL + "/xwzx/xsdt.htm"),
    XYKX("xykx", "校园快讯", AppConfig.BASE_URL + "/xwzx/xykx.htm"),
    GYRW("gyrw", "桂院人物", AppConfig.BASE_URL + "/xwzx/gyrw.htm"),
    MTGY("mtgy", "媒体关注", AppConfig.BASE_URL + "/xwgk2/mtgy.htm");

    private final String key;
    private final String displayName;
    private final String listUrl;

    Category(String key, String displayName, String listUrl) {
        this.key = key;
        this.displayName = displayName;
        this.listUrl = listUrl;
    }

    public String getKey() {
        return key;
    }

    public String getDisplayName() {
        return displayName;
    }

    public String getListUrl() {
        return listUrl;
    }

    /**
     * 按 key 查找分类。
     *
     * @throws ApiException 当 key 未知时
     */
    public static Category fromKey(String key) {
        for (Category c : values()) {
            if (c.key.equals(key)) {
                return c;
            }
        }
        throw new ApiException("未知的新闻分类: " + key);
    }

    /**
     * 全部分类的 key→列表页 URL 映射。
     *
     * <p>保持与重构前 {@code getAllCategories()} 相同的返回结构，
     * 供 {@code /api/news}（无 type）与 {@code /api/news/categories} 使用。</p>
     */
    public static Map<String, String> asKeyUrlMap() {
        Map<String, String> map = new LinkedHashMap<>();
        for (Category c : values()) {
            map.put(c.key, c.listUrl);
        }
        return map;
    }
}

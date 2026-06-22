package com.guilin.news.cache;

import com.guilin.news.config.AppConfig;

import java.io.IOException;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.locks.ReentrantReadWriteLock;

/**
 * 带 TTL 的读写锁缓存，支持"读锁快查 → 写锁双重检查 → 加载"的并发语义。
 *
 * <p>读操作不互相阻塞；写入通过双重检查锁定（Double-Checked Locking）避免并发重复加载。
 * 并发行为与重构前 {@code NewsService} 内联实现一致，此处抽为可复用泛型组件。</p>
 *
 * @param <K> 缓存键
 * @param <V> 缓存值
 */
public class NewsCache<K, V> {

    /** 值加载器，允许抛出 {@link IOException}（如网络抓取失败）。 */
    @FunctionalInterface
    public interface Loader<V> {
        V load() throws IOException;
    }

    private final Map<K, Entry<V>> cache = new HashMap<>();
    private final ReentrantReadWriteLock lock = new ReentrantReadWriteLock();
    private final long ttlMs;

    public NewsCache() {
        this(AppConfig.CACHE_TTL_MS);
    }

    public NewsCache(long ttlMs) {
        this.ttlMs = ttlMs;
    }

    /**
     * 返回缓存值；未命中或已过期时通过 {@code loader} 加载并写入缓存。
     *
     * @throws IOException 当 loader 加载失败时
     */
    public V getOrLoad(K key, Loader<V> loader) throws IOException {
        // 第一层：读锁快速检查
        lock.readLock().lock();
        try {
            Entry<V> entry = cache.get(key);
            if (entry != null && !entry.isExpired(ttlMs)) {
                return entry.value;
            }
        } finally {
            lock.readLock().unlock();
        }

        // 第二层：写锁 + 双重检查，防止并发重复加载
        lock.writeLock().lock();
        try {
            Entry<V> entry = cache.get(key);
            if (entry != null && !entry.isExpired(ttlMs)) {
                return entry.value;
            }
            V value = loader.load();
            cache.put(key, new Entry<>(value));
            return value;
        } finally {
            lock.writeLock().unlock();
        }
    }

    private static final class Entry<V> {
        final long timestamp;
        final V value;

        Entry(V value) {
            this.timestamp = System.currentTimeMillis();
            this.value = value;
        }

        boolean isExpired(long ttlMs) {
            return System.currentTimeMillis() - timestamp > ttlMs;
        }
    }
}

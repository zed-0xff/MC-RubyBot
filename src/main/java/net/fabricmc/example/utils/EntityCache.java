package net.fabricmc.example.utils;

import java.util.*;
import net.minecraft.entity.Entity;
import net.minecraft.client.MinecraftClient;

public class EntityCache {
    private static HashMap<UUID, Entity> cache = new HashMap<UUID, Entity>();
    private static HashMap<UUID, Long> extra = new HashMap<UUID, Long>();

    public static Entity get(UUID uuid) {
        return cache.get(uuid);
    }

    public static void put(Entity entity) {
        cache.put(entity.getUuid(), entity);
    }

    public static void setExtra(UUID uuid, long value) {
        extra.put(uuid, value);
    }

    public static Long getExtra(UUID uuid) {
        return extra.get(uuid);
    }

    public static void cleanup(MinecraftClient mc) {
        for(Iterator<Map.Entry<UUID, Entity>> it = cache.entrySet().iterator(); it.hasNext(); ) {
            Map.Entry<UUID, Entity> entry = it.next();
            Entity entity = entry.getValue();
            if(entity.isRemoved() || !entity.isAlive() || !entity.isInRange(mc.player, 100)){
                extra.remove(entity.getUuid());
                it.remove();
            }
        }
    }
}

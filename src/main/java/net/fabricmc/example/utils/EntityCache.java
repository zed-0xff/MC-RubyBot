package net.fabricmc.example.utils;

import java.util.*;
import net.minecraft.entity.Entity;
import net.minecraft.client.MinecraftClient;

import net.minecraft.scoreboard.AbstractTeam;
import net.minecraft.client.network.OtherClientPlayerEntity;

public class EntityCache {
    private static HashMap<UUID, Entity> cache = new HashMap<UUID, Entity>();
    private static HashMap<Integer, Long> extras = new HashMap<Integer, Long>();
    private static boolean hideOtherPlayers = false;

    public static final int OUTLINE_COLOR = 1;
    public static final int HIDE_ENTITY = 2;

    class Extra {
        Long outlineColor = null;
        boolean hide = false;
    }

    public static Entity get(UUID uuid) {
        return cache.get(uuid);
    }

    public static void put(Entity entity) {
        cache.put(entity.getUuid(), entity);
    }

    public static void setExtra(UUID uuid, int type, long value) {
        extras.put(uuid.hashCode() ^ type, value);
    }

    public static boolean isOtherPlayer(Entity entity) {
        if ( !(entity instanceof OtherClientPlayerEntity) )
            return false;

        // f.ex. goblins and glacites have team "fkt_<smth>"
        AbstractTeam team = entity.getScoreboardTeam();
        if ( team != null && team.getName() != null && team.getName().startsWith("fkt_") ) {
            return false;
        }

        // prolly it's still not comprehensive enough
        return true;
    }

    public static long getExtra(UUID uuid, int type) {
        if ( type == HIDE_ENTITY && hideOtherPlayers ){
            Entity e = cache.get(uuid);
            if ( e != null && isOtherPlayer(e) ){
                return 1; // hide them all!
            }
        }
        return extras.getOrDefault(uuid.hashCode() ^ type, 0L);
    }

    public static void clearExtras() {
        extras.clear();
    }

    public static void cleanup(MinecraftClient mc) {
        for(Iterator<Map.Entry<UUID, Entity>> it = cache.entrySet().iterator(); it.hasNext(); ) {
            Map.Entry<UUID, Entity> entry = it.next();
            Entity entity = entry.getValue();
            if(entity.isRemoved() || !entity.isAlive() || !entity.isInRange(mc.player, 100)){
                // extras kept intentionally
                it.remove();
            }
        }
    }

    public static void setHideOtherPlayers(boolean value) {
        hideOtherPlayers = value;
    }
}

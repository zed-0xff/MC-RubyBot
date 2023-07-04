package net.fabricmc.example.utils;

import java.lang.reflect.Field;
import java.lang.reflect.Type;

import com.google.gson.*;
import com.google.gson.reflect.TypeToken;

import net.minecraft.entity.damage.DamageSource;
import net.minecraft.entity.player.PlayerInventory;
import net.minecraft.util.math.BlockPos.Mutable;
import net.minecraft.util.math.*;
import net.minecraft.client.gui.screen.Screen;

import net.fabricmc.loader.api.metadata.ModMetadata;
import net.minecraft.client.sound.SoundInstance;
import net.minecraft.util.Formatting;

public class Serializer {

    private static class CustomFieldNamingStrategy implements FieldNamingStrategy {
        @Override
        public String translateName(Field field) {
            return "pre_" + field.getName();
        }
    }

    public static final Gson GSON = new GsonBuilder()
        .registerTypeAdapter(
            BlockPos.class, 
            new JsonSerializer<BlockPos>() {
                @Override
                public JsonElement serialize(BlockPos src, Type typeOfSrc, JsonSerializationContext context) {
                    JsonObject obj = new JsonObject();
                    obj.addProperty("x", src.getX());
                    obj.addProperty("y", src.getY());
                    obj.addProperty("z", src.getZ());
                    return obj;
                }
            })
        .registerTypeAdapter(
            BlockPos.Mutable.class, 
            new JsonSerializer<BlockPos.Mutable>() {
                @Override
                public JsonElement serialize(BlockPos.Mutable src, Type typeOfSrc, JsonSerializationContext context) {
                    JsonObject obj = new JsonObject();
                    obj.addProperty("x", src.getX());
                    obj.addProperty("y", src.getY());
                    obj.addProperty("z", src.getZ());
                    return obj;
                }
            })
        .registerTypeAdapter(
            Box.class, 
            new JsonSerializer<Box>() {
                @Override
                public JsonElement serialize(Box src, Type typeOfSrc, JsonSerializationContext context) {
                    JsonObject obj = new JsonObject();
                    obj.addProperty("minX", src.minX);
                    obj.addProperty("minY", src.minY);
                    obj.addProperty("minZ", src.minZ);
                    obj.addProperty("maxX", src.maxX);
                    obj.addProperty("maxY", src.maxY);
                    obj.addProperty("maxZ", src.maxZ);
                    return obj;
                }
            })
        .registerTypeAdapter(
            net.minecraft.client.gui.hud.ClientBossBar.class, 
            new JsonSerializer<net.minecraft.client.gui.hud.ClientBossBar>() {
                @Override
                public JsonElement serialize(net.minecraft.client.gui.hud.ClientBossBar src, Type typeOfSrc, JsonSerializationContext context) {
                    JsonObject obj = new JsonObject();
                    obj.addProperty("percent", src.getPercent());
                    obj.addProperty("name", Formatting.strip(src.getName().getString()));
                    return obj;
                }
            })
        .registerTypeAdapter(
            DamageSource.class, 
            new JsonSerializer<DamageSource>() {
                @Override
                public JsonElement serialize(DamageSource src, Type typeOfSrc, JsonSerializationContext context) {
                    JsonObject obj = new JsonObject();
                    obj.addProperty("name", src.getName());
                    obj.add("position", toJsonTree(src.getPosition()));
                    obj.add("source", toJsonTree(src.getSource()));
                    obj.add("attacker", toJsonTree(src.getAttacker()));
                    //obj.addProperty("outOfWorld", src.isOutOfWorld());
                    return obj;
                }
            })
        .registerTypeAdapter(
            ModMetadata.class,
            new JsonSerializer<ModMetadata>() {
                @Override
                public JsonElement serialize(ModMetadata src, Type typeOfSrc, JsonSerializationContext context) {
                    JsonObject obj = new JsonObject();
                    obj.addProperty("id", src.getId());
                    obj.addProperty("name", src.getName());
                    obj.addProperty("type", src.getType());
                    obj.addProperty("version", src.getVersion().toString());
                    return obj;
                }
            })
        .registerTypeAdapter(
            PlayerInventory.class, 
            new JsonSerializer<PlayerInventory>() {
                @Override
                public JsonElement serialize(PlayerInventory src, Type typeOfSrc, JsonSerializationContext context) {
                    JsonObject obj = new JsonObject();
                    obj.addProperty("selectedSlot", src.selectedSlot);
                    obj.addProperty("swappableSlot", src.getSwappableHotbarSlot());
                    return obj;
                }
            })
        // XXX not works!
        .registerTypeAdapter(
            Screen.class, 
            new JsonSerializer<Screen>() {
                @Override
                public JsonElement serialize(Screen src, Type typeOfSrc, JsonSerializationContext context) {
                    JsonObject obj = new JsonObject();
                    obj.addProperty("title", src.getTitle().getString());
                    obj.addProperty("children", src.children().size());
                    obj.addProperty("width", src.width);
                    obj.addProperty("height", src.height);
                    return obj;
                }
            })
//        .registerTypeAdapter(
//            SoundInstance.class, 
//            new JsonSerializer<SoundInstance>() {
//                @Override
//                public JsonElement serialize(SoundInstance src, Type typeOfSrc, JsonSerializationContext context) {
//                    JsonObject obj = new JsonObject();
//                    obj.addProperty("id", src.getId().toString());
//                    obj.addProperty("pitch", src.getPitch());
//                    obj.addProperty("volume", src.getVolume());
//                    if (src.isRelative()) {
//                        obj.addProperty("relative", src.isRelative());
//                    }
//                    obj.addProperty("x", src.getX());
//                    obj.addProperty("y", src.getY());
//                    obj.addProperty("z", src.getZ());
//                    // a sound can also have Entity / ClientPlayerEntity (for elytra)
//                    return obj;
//                }
//            })
        .registerTypeAdapter(
            Vec3d.class, 
            new JsonSerializer<Vec3d>() {
                @Override
                public JsonElement serialize(Vec3d src, Type typeOfSrc, JsonSerializationContext context) {
                    JsonObject obj = new JsonObject();
                    obj.addProperty("x", src.x);
                    obj.addProperty("y", src.y);
                    obj.addProperty("z", src.z);
                    return obj;
                }
            })
        .registerTypeAdapter(
            Vec3i.class, 
            new JsonSerializer<Vec3i>() {
                @Override
                public JsonElement serialize(Vec3i src, Type typeOfSrc, JsonSerializationContext context) {
                    JsonObject obj = new JsonObject();
                    obj.addProperty("x", src.getX());
                    obj.addProperty("y", src.getY());
                    obj.addProperty("z", src.getZ());
                    return obj;
                }
            })
        .registerTypeAdapter(
            ChunkPos.class, 
            new JsonSerializer<ChunkPos>() {
                @Override
                public JsonElement serialize(ChunkPos src, Type typeOfSrc, JsonSerializationContext context) {
                    JsonObject obj = new JsonObject();
                    obj.addProperty("x", src.x);
                    obj.addProperty("z", src.z);
                    return obj;
                }
            })
        .create();

    public static JsonElement toJsonTree(Object src) {
        return GSON.toJsonTree(src);
    }

    public static JsonElement toJsonTree(Object src, Type typeOfSrc) {
        return GSON.toJsonTree(src, typeOfSrc);
    }
}

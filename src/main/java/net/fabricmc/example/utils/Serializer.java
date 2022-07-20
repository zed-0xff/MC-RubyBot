package net.fabricmc.example.utils;

import java.lang.reflect.Field;
import java.lang.reflect.Type;

import com.google.gson.*;
import com.google.gson.reflect.TypeToken;

import net.minecraft.entity.damage.DamageSource;
import net.minecraft.entity.player.PlayerInventory;
import net.minecraft.util.math.BlockPos;
import net.minecraft.util.math.Box;
import net.minecraft.util.math.Vec3d;
import net.minecraft.util.math.Vec3i;

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
            DamageSource.class, 
            new JsonSerializer<DamageSource>() {
                @Override
                public JsonElement serialize(DamageSource src, Type typeOfSrc, JsonSerializationContext context) {
                    JsonObject obj = new JsonObject();
                    obj.addProperty("name", src.name);
                    obj.add("position", toJsonTree(src.getPosition()));
                    obj.add("source", toJsonTree(src.getSource()));
                    obj.add("attacker", toJsonTree(src.getAttacker()));
                    obj.addProperty("outOfWorld", src.isOutOfWorld());
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
                    return obj;
                }
            })
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
        .create();

    public static JsonElement toJsonTree(Object src) {
        return GSON.toJsonTree(src);
    }
}

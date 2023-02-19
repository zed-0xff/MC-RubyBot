package net.fabricmc.example.utils;

import java.util.HashMap;

public class Mappings {

    public static HashMap<String, Class> SHORT_2_CLASS = new HashMap<String, Class>() {{
        put("AnimalEntity",            net.minecraft.entity.passive.AnimalEntity.class);
        put("ArmorStandEntity",        net.minecraft.entity.decoration.ArmorStandEntity.class);
        put("BatEntity",               net.minecraft.entity.passive.BatEntity.class);
        put("ChickenEntity",           net.minecraft.entity.passive.ChickenEntity.class);
        put("CowEntity",               net.minecraft.entity.passive.CowEntity.class);
        put("Entity",                  net.minecraft.entity.Entity.class);
        put("FishingBobberEntity",     net.minecraft.entity.projectile.FishingBobberEntity.class);
        put("HorseEntity",             net.minecraft.entity.passive.HorseEntity.class);
        put("HostileEntity",           net.minecraft.entity.mob.HostileEntity.class);
        put("ItemEntity",              net.minecraft.entity.ItemEntity.class);
        put("LivingEntity",            net.minecraft.entity.LivingEntity.class);
        put("MobEntity",               net.minecraft.entity.mob.MobEntity.class);
        put("OtherClientPlayerEntity", net.minecraft.client.network.OtherClientPlayerEntity.class);
        put("PathAwareEntity",         net.minecraft.entity.mob.PathAwareEntity.class);
        put("PlayerEntity",            net.minecraft.entity.player.PlayerEntity.class);
        put("ProjectileEntity",        net.minecraft.entity.projectile.ProjectileEntity.class);
        put("RabbitEntity",            net.minecraft.entity.passive.RabbitEntity.class);
        put("SheepEntity",             net.minecraft.entity.passive.SheepEntity.class);
        put("ZombieEntity",            net.minecraft.entity.mob.ZombieEntity.class);
    }};

    public static HashMap<Class, String> CLASS_2_SHORT = new HashMap<Class, String>() {{
        for (String key : SHORT_2_CLASS.keySet()){
            put(SHORT_2_CLASS.get(key), key);
        }
    }};

    public static String class2short(Class c) {
        return CLASS_2_SHORT.get(c);
    }

    public static Class short2class(String s) {
        return SHORT_2_CLASS.get(s);
    }
}

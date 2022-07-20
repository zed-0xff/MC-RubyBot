package net.fabricmc.example.utils;

import net.fabricmc.example.ExampleMod;

import net.minecraft.entity.mob.MobEntity;
import net.minecraft.entity.ai.pathing.MobNavigation;
import net.minecraft.world.World;
import net.minecraft.util.math.Vec3d;

public class AI extends MobNavigation {

    public AI(MobEntity mob, World world) {
        super(mob, world);
    }

    public void setPosition(Vec3d pos) {
        ExampleMod.LOGGER.info("[d] before add " + getPos().toString());
        getPos().add(pos);
        ExampleMod.LOGGER.info("[d] after add  " + getPos().toString());
    }

    public Vec3d getPos() {
        return super.getPos();
    }

    public boolean canPathDirectlyThrough(Vec3d origin, Vec3d target) {
        return super.canPathDirectlyThrough(origin, target);
    }
}

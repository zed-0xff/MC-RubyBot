package net.fabricmc.example.mixin;

import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.gen.Invoker;

import net.minecraft.entity.LivingEntity;
import net.minecraft.entity.EntityPose;
import net.minecraft.entity.EntityDimensions;

@Mixin(LivingEntity.class)
public interface LivingEntityAccessor {
    @Invoker
    float invokeGetActiveEyeHeight(EntityPose pose, EntityDimensions dimensions);
}

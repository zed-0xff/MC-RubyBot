package net.fabricmc.example.mixin;

import net.fabricmc.example.ExampleMod;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

import net.minecraft.entity.player.PlayerEntity;
import net.minecraft.client.MinecraftClient;
import net.minecraft.client.particle.ItemPickupParticle;
import net.minecraft.client.render.entity.EntityRenderDispatcher;
import net.minecraft.client.render.BufferBuilderStorage;
import net.minecraft.client.world.ClientWorld;
import net.minecraft.entity.Entity;
import net.minecraft.util.math.Vec3d;

@Mixin(ItemPickupParticle.class)
public class MixinItemPickupParticle {
    @Inject(
        method = "<init>(Lnet/minecraft/client/render/entity/EntityRenderDispatcher;Lnet/minecraft/client/render/BufferBuilderStorage;Lnet/minecraft/client/world/ClientWorld;Lnet/minecraft/entity/Entity;Lnet/minecraft/entity/Entity;Lnet/minecraft/util/math/Vec3d;)V",
        at = @At("RETURN")
    )
        private void init(EntityRenderDispatcher dispatcher, BufferBuilderStorage bufferStorage, ClientWorld world, Entity itemEntity, Entity interactingEntity, Vec3d velocity, CallbackInfo ci) {
            if ( ExampleMod.LOGGER == null )
                return;

            MinecraftClient mc = MinecraftClient.getInstance();
            if ( mc.player == null )
                return;

            if ( interactingEntity != mc.player )
                return;

            if ( itemEntity instanceof net.minecraft.entity.ExperienceOrbEntity ){
                ExampleMod.LOGGER.info("[d] ItemPickupParticle: " + itemEntity + " exp=" + ((net.minecraft.entity.ExperienceOrbEntity)itemEntity).getExperienceAmount());
            } else {
                ExampleMod.LOGGER.info("[d] ItemPickupParticle: " + itemEntity);
            }
        }
}

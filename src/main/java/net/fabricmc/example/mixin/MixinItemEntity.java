package net.fabricmc.example.mixin;

import net.fabricmc.example.ExampleMod;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

import net.minecraft.entity.ItemEntity;
import net.minecraft.entity.player.PlayerEntity;
import net.minecraft.client.MinecraftClient;
import net.minecraft.client.particle.ItemPickupParticle;
import net.minecraft.client.render.entity.EntityRenderDispatcher;
import net.minecraft.client.render.BufferBuilderStorage;
import net.minecraft.client.world.ClientWorld;
import net.minecraft.entity.Entity;
import net.minecraft.util.math.Vec3d;

@Mixin(ItemEntity.class)
public class MixinItemEntity {

    @Inject(
        method = "onPlayerCollision(Lnet/minecraft/entity/player/PlayerEntity;)V",
        at = @At("HEAD")
    )
        private void onPlayerCollision(PlayerEntity player, CallbackInfo ci) {
            if ( ExampleMod.LOGGER == null )
                return;

            MinecraftClient mc = MinecraftClient.getInstance();
            if ( mc.player == null )
                return;

            if ( player != mc.player )
                return;

            ExampleMod.LOGGER.info("[d] ItemEntity.onPlayerCollision " + 
                    ((ItemEntity)(Object)this).getStack() + " " +
                    ((ItemEntity)(Object)this).getOwner());
        }
}

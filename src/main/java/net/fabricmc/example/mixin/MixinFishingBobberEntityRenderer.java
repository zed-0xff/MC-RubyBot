package net.fabricmc.example.mixin;

import net.fabricmc.example.ExampleMod;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

import net.minecraft.client.MinecraftClient;
import net.minecraft.client.render.entity.FishingBobberEntityRenderer;
import net.minecraft.client.render.Frustum;
import net.minecraft.entity.projectile.FishingBobberEntity;
import net.minecraft.client.util.math.MatrixStack;
import net.minecraft.client.render.VertexConsumerProvider;
import net.minecraft.entity.Entity;

import net.fabricmc.example.handlers.StatusHandler;

// hide other players fishing bobbers
@Mixin(FishingBobberEntityRenderer.class)
public class MixinFishingBobberEntityRenderer {
    @Inject(method = "render(Lnet/minecraft/entity/projectile/FishingBobberEntity;FFLnet/minecraft/client/util/math/MatrixStack;Lnet/minecraft/client/render/VertexConsumerProvider;I)V", at = @At(value = "HEAD"), cancellable = true)
    public void render(FishingBobberEntity bobber, float float2, float float3, MatrixStack matrixStack, VertexConsumerProvider vertexConsumerProvider, int int2, CallbackInfo ci) {
        MinecraftClient mc = MinecraftClient.getInstance();
        if( bobber == null )
            return;
        if( bobber.getPlayerOwner() == mc.player ) {
            //StatusHandler.logEntity(bobber);
        } else {
            // hide
            ci.cancel();
        }
	}
}

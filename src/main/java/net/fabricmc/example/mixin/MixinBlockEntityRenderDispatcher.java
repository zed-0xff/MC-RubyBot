package net.fabricmc.example.mixin;

import net.fabricmc.example.ExampleMod;
import net.fabricmc.example.utils.EntityCache;

import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfoReturnable;

import net.minecraft.client.render.block.entity.BlockEntityRenderDispatcher;
import net.minecraft.block.entity.BlockEntity;
import net.minecraft.client.util.math.MatrixStack;
import net.minecraft.client.render.VertexConsumerProvider;
import net.minecraft.client.render.OutlineVertexConsumerProvider;

import net.minecraft.client.MinecraftClient;
import net.minecraft.client.render.TexturedRenderLayers;

//import baritone.utils.IRenderer;

@Mixin(BlockEntityRenderDispatcher.class)
public class MixinBlockEntityRenderDispatcher {
    @Inject(
        method = "render(Lnet/minecraft/block/entity/BlockEntity;FLnet/minecraft/client/util/math/MatrixStack;Lnet/minecraft/client/render/VertexConsumerProvider;)V",
        at = @At("HEAD")
    )
        private void render(BlockEntity entity,
                float tickDelta,
                MatrixStack matrices,
                VertexConsumerProvider vertexConsumers,
                CallbackInfo ci)
        {
//            MinecraftClient mc = MinecraftClient.getInstance();
//            ((WorldRendererAccessor)mc.worldRenderer).invokeDrawBlockOutline(
//                    matrices,
//                    vertexConsumers.getBuffer(TexturedRenderLayers.getEntityCutout()),
//                    mc.player,
//                    mc.player.getEyePos().getX(),
//                    mc.player.getEyePos().getY(),
//                    mc.player.getEyePos().getZ(),
//                    entity.getPos(),
//                    entity.getCachedState()
//                    );
        }
}

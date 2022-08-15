package net.fabricmc.example.mixin;

import net.fabricmc.example.utils.EntityCache;

import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfoReturnable;

import net.minecraft.client.render.entity.EntityRenderDispatcher;
import net.minecraft.entity.Entity;
import net.minecraft.client.util.math.MatrixStack;
import net.minecraft.client.render.VertexConsumerProvider;
import net.minecraft.client.render.OutlineVertexConsumerProvider;
import net.minecraft.client.render.VertexConsumer;
import net.minecraft.client.render.TexturedRenderLayers;

@Mixin(EntityRenderDispatcher.class)
public class MixinEntityRenderDispatcher {
    @Inject(
        method = "render(Lnet/minecraft/entity/Entity;DDDFFLnet/minecraft/client/util/math/MatrixStack;Lnet/minecraft/client/render/VertexConsumerProvider;I)V",
        at = @At("HEAD")
    )
        private void render(Entity entity,
                double x,
                double y,
                double z,
                float yaw,
                float tickDelta,
                MatrixStack matrices,
                VertexConsumerProvider vertexConsumers,
                int light,
                CallbackInfo ci)
        {
            Long outlineColor = EntityCache.getExtra(entity.getUuid());
            if ( outlineColor != null && outlineColor != 0 ) {
                if ( vertexConsumers instanceof OutlineVertexConsumerProvider ) {
                    ((OutlineVertexConsumerProvider)vertexConsumers).setColor(
                        (int)((outlineColor >> 24) & 0xff),
                        (int)((outlineColor >> 16) & 0xff),
                        (int)((outlineColor >> 8) & 0xff),
                        (int)(outlineColor & 0xff)
                        );
                }
            }
        }
}

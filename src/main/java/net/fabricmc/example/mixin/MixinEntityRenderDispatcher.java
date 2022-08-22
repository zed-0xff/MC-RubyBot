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
import net.minecraft.client.render.Frustum;

@Mixin(EntityRenderDispatcher.class)
public class MixinEntityRenderDispatcher {
    @Inject(
        method = "render(Lnet/minecraft/entity/Entity;DDDFFLnet/minecraft/client/util/math/MatrixStack;Lnet/minecraft/client/render/VertexConsumerProvider;I)V",
        at = @At("HEAD"),
        cancellable = true
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
            long hide = EntityCache.getExtra(entity.getUuid(), EntityCache.HIDE_ENTITY);
            if ( hide == 1 ) {
                ci.cancel();
                return;
            }

            long outlineColor = EntityCache.getExtra(entity.getUuid(), EntityCache.OUTLINE_COLOR);
            if ( outlineColor != 0 ) {
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

    @Inject(
    method = "shouldRender(Lnet/minecraft/entity/Entity;Lnet/minecraft/client/render/Frustum;DDD)Z",
    at = @At("HEAD"),
    cancellable = true
    )
        private void shouldRender(Entity entity, Frustum frustum, double x, double y, double z,
                CallbackInfoReturnable<Boolean> cir) 
        {
            long hide = EntityCache.getExtra(entity.getUuid(), EntityCache.HIDE_ENTITY);
            if ( hide == 1 ) {
                cir.setReturnValue(false);
            }
        }
}

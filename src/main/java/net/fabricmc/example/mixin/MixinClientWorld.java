package net.fabricmc.example.mixin;

import net.fabricmc.example.ExampleMod;
//import net.fabricmc.example.utils.Serializer;
import net.fabricmc.example.handlers.ActionHandler;

import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfoReturnable;

import net.minecraft.client.world.ClientWorld;
import net.minecraft.util.math.BlockPos;
import net.minecraft.block.BlockState;
import net.minecraft.particle.ParticleEffect;

import com.google.gson.JsonObject;

@Mixin(ClientWorld.class)
public class MixinClientWorld {

    private static JsonObject serialize(
            ParticleEffect parameters,
            double x, double y, double z,
            double velocityX, double velocityY, double velocityZ
            ) 
    {
        JsonObject obj = new JsonObject();
        obj.addProperty("effect", parameters.asString());
        obj.addProperty("x", x);
        obj.addProperty("y", y);
        obj.addProperty("z", z);
        if ( velocityX != 0 || velocityY != 0 || velocityZ != 0 ){
            obj.addProperty("velocityX", velocityX);
            obj.addProperty("velocityY", velocityY);
            obj.addProperty("velocityZ", velocityZ);
        }
        return obj;
    }

    @Inject(
        method = "addParticle(Lnet/minecraft/util/math/BlockPos;Lnet/minecraft/block/BlockState;Lnet/minecraft/particle/ParticleEffect;Z)V",
        at = @At("HEAD")
    )
    private void addParticle(BlockPos pos, BlockState state, ParticleEffect parameters, boolean bool, CallbackInfo ci) {
        if ( ExampleMod.LOGGER == null ) return;
        //ExampleMod.LOGGER.info("[d] addParticle " + pos + ", " + parameters + ", " + bool);
        ActionHandler.particleLog.add(serialize(parameters, pos.getX(), pos.getY(), pos.getZ(), 0, 0, 0));
    }

    @Inject(
        method = "addParticle(Lnet/minecraft/particle/ParticleEffect;DDDDDD)V",
        at = @At("HEAD")
    )
    private void addParticle(ParticleEffect parameters,
        double x,
        double y,
        double z,
        double velocityX,
        double velocityY,
        double velocityZ,
        CallbackInfo ci
    ) {
        if ( ExampleMod.LOGGER == null ) return;
        //ExampleMod.LOGGER.info("[d] addParticle2 " + x + ", " + y + ", " + z + ", " + parameters.asString());
        ActionHandler.particleLog.add(serialize(parameters, x, y, z, velocityX, velocityY, velocityZ ));
    }

    @Inject(
        method = "addParticle(Lnet/minecraft/particle/ParticleEffect;ZDDDDDD)V",
        at = @At("HEAD")
    )
    private void addParticle(ParticleEffect parameters,
        boolean alwaysSpawn,
        double x,
        double y,
        double z,
        double velocityX,
        double velocityY,
        double velocityZ,
        CallbackInfo ci
    ) {
        if ( ExampleMod.LOGGER == null ) return;
        //if ( velocityX != 0 || velocityY != 0 || velocityZ != 0 ) return;
        //ExampleMod.LOGGER.info("[d] addParticle3 " + alwaysSpawn + ", " + x + ", " + y + ", " + z + ", " + parameters.asString());
        //ActionHandler.soundLog.add(Serializer.toJsonTree(parameters));
        ActionHandler.particleLog.add(serialize(parameters, x, y, z, velocityX, velocityY, velocityZ ));
    }
}

package net.fabricmc.example.mixin;

import net.fabricmc.example.ExampleMod;

import java.util.List;

import org.spongepowered.asm.mixin.Final;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.Shadow;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.Redirect;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfoReturnable;

import net.minecraft.command.CommandSource;
import net.minecraft.client.network.ClientCommandSource;
import net.minecraft.client.gui.screen.CommandSuggestor;
import net.minecraft.client.gui.widget.TextFieldWidget;

import com.mojang.brigadier.CommandDispatcher;
import com.mojang.brigadier.ParseResults;
import com.mojang.brigadier.context.StringRange;
import com.mojang.brigadier.suggestion.Suggestion;
import com.mojang.brigadier.suggestion.Suggestions;
import com.mojang.brigadier.context.CommandContext;
import com.mojang.brigadier.Message;

import java.util.concurrent.CompletableFuture;
import java.util.Collection;
import java.util.ArrayList;

@Mixin(Message.class)
public class MixinCommandDispatcher {
    // public String[] getAllUsage(final CommandNode<S> node, final S source, final boolean restricted) {
//    @Inject( method = "getAllUsage(Lcom/mojang/brigadier/tree/CommandNode;ZZ)V", at = @At("HEAD"))
//    private void foo(CallbackInfoReturnable<String[]> ci) {
//    }
//    @Inject( method = "getString()Ljava/lang/String;", at = @At("HEAD"))
//    public void foo(CallbackInfoReturnable<String> cir) {
//    }
}
